#!/bin/bash

# Function to check if Edge is installed
check_edge() {
    if [ -f "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" ]; then
        return 0
    else
        return 1
    fi
}

# Function to create Edge PWA
create_edge_pwa() {
    local url=$1
    local name=$2

    if ! check_edge; then
        echo "Microsoft Edge is not installed. Please install it first."
        return 1
    fi

    # Create PWA using Edge
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
        --app="$url" \
        --app-id="$(echo -n "$url" | md5)" \
        --app-name="$name" \
        --create-shell-shortcuts
    
    echo "Edge PWA created successfully for $name"
}

# Function to create Safari PWA
create_safari_pwa() {
    local url=$1
    local name=$2
    
    if ! command -v "osascript" >/dev/null 2>&1; then
        echo "AppleScript is not available. Please ensure you're running this on macOS."
        return 1
    fi
    
    echo "Creating Safari PWA for $name at $url..."
    
    # Create the Apple Script
    cat << EOF > "/tmp/create_webapp.scpt"
tell application "Safari"
    activate
    make new document with properties {URL:"$url"}
    delay 2
    tell application "System Events"
        click menu item "Add to Dock…" of menu "File" of menu bar 1 of application process "Safari"
        delay 1
        keystroke "$name"
        delay 1
        click button "Add" of sheet 1 of window 1 of application process "Safari"
    end tell
    delay 1
    close document 1
end tell
EOF

    # Run the Apple Script
    osascript "/tmp/create_webapp.scpt"
    local status=$?
    rm "/tmp/create_webapp.scpt"
    
    if [ $status -eq 0 ]; then
        echo "Safari PWA created successfully for $name"
    else
        echo "Failed to create Safari PWA. Make sure Safari is running and accessibility permissions are granted."
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <url> [--name <name>] [--browser <edge|safari>]"
    echo "Examples:"
    echo "  $0 https://example.com --browser safari"
    echo "  $0 https://example.com --name \"My App\" --browser edge"
    echo "  $0 https://example.com --name \"My App\"  # defaults to edge"
    echo "  $0 https://example.com  # uses domain name as app name, edge browser"
}

# Main script
main() {
    # Default values
    local url=""
    local name=""
    local browser="edge"

    # Must have at least a URL
    if [ "$#" -lt 1 ]; then
        show_usage
        return 1
    fi

    # Get the URL (first argument)
    url="$1"
    shift

    # Extract domain name for default app name
    name=$(echo "$url" | awk -F[/:] '{print $4}')

    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)
                name="$2"
                shift 2
                ;;
            --browser)
                browser="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                return 1
                ;;
        esac
    done

    echo "Creating PWA with:"
    echo "  URL: $url"
    echo "  Name: $name"
    echo "  Browser: $browser"
    echo

    # Create PWA based on browser choice
    case "$browser" in
        "safari")
            create_safari_pwa "$url" "$name"
            ;;
        "edge")
            create_edge_pwa "$url" "$name"
            ;;
        *)
            echo "Invalid browser specified. Use 'edge' or 'safari'"
            return 1
            ;;
    esac
}

# Run the script with provided arguments
main "$@"