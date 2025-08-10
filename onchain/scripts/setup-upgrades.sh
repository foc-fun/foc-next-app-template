#!/bin/bash

# Counter Game Upgrade Setup Script
# This script configures upgrade settings from a JSON configuration file

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ONCHAIN_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$ONCHAIN_DIR/upgrades.json"
NETWORK="${NETWORK:-devnet}"
RPC_URL="${RPC_URL:-http://localhost:5050}"
ACCOUNT="${ACCOUNT:-devnet}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v sncast &> /dev/null; then
        log_error "sncast not found. Please install Starknet Foundry."
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq not found. Please install jq for JSON processing."
        exit 1
    fi
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    log_success "Dependencies check passed"
}

# Validate configuration file
validate_config() {
    log_info "Validating configuration file..."
    
    # Check if JSON is valid
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        log_error "Invalid JSON in configuration file"
        exit 1
    fi
    
    # Check required fields
    local upgrade_count=$(jq '.upgrades | length' "$CONFIG_FILE")
    if [[ "$upgrade_count" -eq 0 ]]; then
        log_error "No upgrades found in configuration file"
        exit 1
    fi
    
    log_success "Configuration validation passed ($upgrade_count upgrades found)"
}

# Setup single upgrade
setup_upgrade() {
    local upgrade_data="$1"
    local id=$(echo "$upgrade_data" | jq -r '.id')
    local name=$(echo "$upgrade_data" | jq -r '.name')
    local cost=$(echo "$upgrade_data" | jq -r '.cost')
    local increment_value=$(echo "$upgrade_data" | jq -r '.increment_value')
    
    log_info "Setting up upgrade: $name (ID: $id)"
    
    # Prepare sncast command
    local sncast_cmd="sncast --url $RPC_URL --account $ACCOUNT"
    
    # Check if upgrade already exists
    local existing_upgrade
    existing_upgrade=$($sncast_cmd call \
        --contract-address "$CONTRACT_ADDRESS" \
        --function "get_upgrade_config" \
        --calldata "$id" 2>/dev/null || echo "")
    
    if [[ -n "$existing_upgrade" ]] && [[ "$existing_upgrade" != *"0x0"* ]]; then
        log_info "Upgrade $id already exists, updating configuration..."
        
        # Update existing upgrade
        $sncast_cmd invoke \
            --contract-address "$CONTRACT_ADDRESS" \
            --function "set_upgrade_config" \
            --calldata "$id" "$cost" "$increment_value"
        
        if [[ $? -eq 0 ]]; then
            log_success "Updated upgrade $id: $name (Cost: $cost, Power: ${increment_value}x)"
        else
            log_error "Failed to update upgrade $id"
            return 1
        fi
    else
        log_info "Adding new upgrade $id..."
        
        # Add new upgrade
        $sncast_cmd invoke \
            --contract-address "$CONTRACT_ADDRESS" \
            --function "add_new_upgrade" \
            --calldata "$id" "$cost" "$increment_value"
        
        if [[ $? -eq 0 ]]; then
            log_success "Added new upgrade $id: $name (Cost: $cost, Power: ${increment_value}x)"
        else
            log_error "Failed to add upgrade $id"
            return 1
        fi
    fi
}

# Setup all upgrades
setup_all_upgrades() {
    log_info "Starting upgrade configuration..."
    
    local upgrade_count=$(jq '.upgrades | length' "$CONFIG_FILE")
    local success_count=0
    
    for (( i=0; i<upgrade_count; i++ )); do
        local upgrade_data=$(jq ".upgrades[$i]" "$CONFIG_FILE")
        
        if setup_upgrade "$upgrade_data"; then
            ((success_count++))
        fi
        
        # Small delay between operations
        sleep 1
    done
    
    log_info "Upgrade setup completed: $success_count/$upgrade_count successful"
    
    if [[ $success_count -eq $upgrade_count ]]; then
        log_success "All upgrades configured successfully!"
    else
        log_warning "Some upgrades failed to configure"
        return 1
    fi
}

# Display current upgrade configuration
show_current_config() {
    log_info "Current upgrade configuration:"
    
    local sncast_cmd="sncast --url $RPC_URL --account $ACCOUNT"
    
    # Get all upgrades
    local upgrades_result
    upgrades_result=$($sncast_cmd call \
        --contract-address "$CONTRACT_ADDRESS" \
        --function "get_all_upgrades" 2>/dev/null || echo "")
    
    if [[ -n "$upgrades_result" ]]; then
        echo "$upgrades_result"
    else
        log_warning "Could not retrieve current upgrades"
    fi
}

# Main execution
main() {
    log_info "Counter Game Upgrade Setup Script"
    log_info "=================================="
    log_info "Network: $NETWORK"
    log_info "RPC URL: $RPC_URL"
    log_info "Account: $ACCOUNT"
    log_info "Config: $CONFIG_FILE"
    echo ""
    
    # Check for contract address
    if [[ -z "$CONTRACT_ADDRESS" ]]; then
        log_error "CONTRACT_ADDRESS environment variable is required"
        log_info "Usage: CONTRACT_ADDRESS=0x... ./setup-upgrades.sh"
        exit 1
    fi
    
    log_info "Contract Address: $CONTRACT_ADDRESS"
    echo ""
    
    check_dependencies
    validate_config
    
    # Show current config before changes
    if [[ "$1" != "--skip-current" ]]; then
        show_current_config
        echo ""
    fi
    
    setup_all_upgrades
    
    echo ""
    log_success "Upgrade setup completed!"
    
    # Show final config
    log_info "Final configuration:"
    show_current_config
}

# Help function
show_help() {
    echo "Counter Game Upgrade Setup Script"
    echo ""
    echo "Usage: CONTRACT_ADDRESS=0x... ./setup-upgrades.sh [options]"
    echo ""
    echo "Environment Variables:"
    echo "  CONTRACT_ADDRESS    (required) Address of deployed CounterGame contract"
    echo "  NETWORK            (optional) Target network (default: devnet)"
    echo "  RPC_URL            (optional) RPC endpoint (default: http://localhost:5050)"
    echo "  ACCOUNT            (optional) Sncast account (default: devnet)"
    echo ""
    echo "Options:"
    echo "  --skip-current     Skip showing current configuration before setup"
    echo "  --help, -h         Show this help message"
    echo ""
    echo "Examples:"
    echo "  CONTRACT_ADDRESS=0x123... ./setup-upgrades.sh"
    echo "  NETWORK=sepolia RPC_URL=https://... CONTRACT_ADDRESS=0x123... ./setup-upgrades.sh"
}

# Check for help flag
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Run main function
main "$@"