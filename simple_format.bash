#!/bin/bash

# Function to check if file exists and return the full path
file_exists() {
    local file_path="$1"
    
    # Check if file exists as is
    if [[ -f "$file_path" ]]; then
        echo "$file_path"
        return 0
    # Check if file exists relative to parent directory
    elif [[ -f "../$file_path" ]]; then
        echo "../$file_path"
        return 0
    # Check if file exists in study directory
    elif [[ -f "/home/aj/dev/study/$file_path" ]]; then
        echo "/home/aj/dev/study/$file_path"
        return 0
    # Check if file exists in frontend/src directory
    elif [[ -f "/home/aj/dev/study/frontend/src/$file_path" ]]; then
        echo "/home/aj/dev/study/frontend/src/$file_path"
        return 0
    # Check if file exists in actions-runner directory
    elif [[ -f "/home/aj/dev/actions-runner/_work/study/study/$file_path" ]]; then
        echo "/home/aj/dev/actions-runner/_work/study/study/$file_path"
        return 0
    # Check if file exists in actions-runner frontend/src directory
    elif [[ -f "/home/aj/dev/actions-runner/_work/study/study/frontend/src/$file_path" ]]; then
        echo "/home/aj/dev/actions-runner/_work/study/study/frontend/src/$file_path"
        return 0
    # Special case for input.svelte
    elif [[ "$file_path" == *"input.svelte"* || "$file_path" == "lib/utils/popups/input.svelte" ]]; then
        if [[ -f "/home/aj/dev/study/frontend/src/lib/utils/popups/input.svelte" ]]; then
            echo "/home/aj/dev/study/frontend/src/lib/utils/popups/input.svelte"
            return 0
        elif [[ -f "/home/aj/dev/actions-runner/_work/study/study/frontend/src/lib/utils/popups/input.svelte" ]]; then
            echo "/home/aj/dev/actions-runner/_work/study/study/frontend/src/lib/utils/popups/input.svelte"
            return 0
        fi
    else
        return 1
    fi
}

# Function to find a file using fuzzy search
find_file_fuzzy() {
    local search_term="$1"
    local found_file=""
    
    # Try to find in current and parent directories
    found_file=$(find . .. -type f -name "*${search_term}*" 2>/dev/null | grep -v "node_modules" | grep -v ".git" | head -1)
    if [[ -n "$found_file" ]]; then
        echo "$found_file"
        return 0
    fi
    
    # Try case-insensitive search
    found_file=$(find . .. -type f -iname "*${search_term}*" 2>/dev/null | grep -v "node_modules" | grep -v ".git" | head -1)
    if [[ -n "$found_file" ]]; then
        echo "$found_file"
        return 0
    fi
    
    # Try in study directory
    found_file=$(find /home/aj/dev/study -type f -name "*${search_term}*" 2>/dev/null | grep -v "node_modules" | grep -v ".git" | head -1)
    if [[ -n "$found_file" ]]; then
        echo "$found_file"
        return 0
    fi
    
    # Try in actions-runner directory
    found_file=$(find /home/aj/dev/actions-runner/_work/study/study -type f -name "*${search_term}*" 2>/dev/null | grep -v "node_modules" | grep -v ".git" | head -1)
    if [[ -n "$found_file" ]]; then
        echo "$found_file"
        return 0
    fi
    
    # Special case for input.svelte
    if [[ "$search_term" == *"input"* || "$search_term" == *"svelte"* ]]; then
        if [[ -f "/home/aj/dev/study/frontend/src/lib/utils/popups/input.svelte" ]]; then
            echo "/home/aj/dev/study/frontend/src/lib/utils/popups/input.svelte"
            return 0
        elif [[ -f "/home/aj/dev/actions-runner/_work/study/study/frontend/src/lib/utils/popups/input.svelte" ]]; then
            echo "/home/aj/dev/actions-runner/_work/study/study/frontend/src/lib/utils/popups/input.svelte"
            return 0
        fi
    fi
    
    return 1
}

# Function to generate context from files
generate_context() {
    OUTPUT_FILE="llm_context.txt"
    # Clear the context file
    > "$OUTPUT_FILE"
    echo "Cleared context file for new query"

    # Add initial headers
    echo "# Inputs" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "## Current File" >> "$OUTPUT_FILE"
    echo "Here is the file I'm looking at. It might be truncated from above and below and, if so, is centered around my cursor." >> "$OUTPUT_FILE"

    # Process each file in scripts.txt for the code block header
    while IFS= read -r file_path; do
        # Skip empty lines and comments
        [[ -z "$file_path" || "$file_path" =~ ^#.*$ ]] && continue
        
        # Add file path as a code block header
        echo "\`\`\`${file_path}" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    done < "scripts.txt"

    echo "" >> "$OUTPUT_FILE"
    echo "<potential_codebase_context>" >> "$OUTPUT_FILE"
    echo "## Potentially Relevant Code Snippets from the current Codebase" >> "$OUTPUT_FILE"

    # Add actual file contents
    while IFS= read -r file_path; do
        # Skip empty lines and comments
        [[ -z "$file_path" || "$file_path" =~ ^#.*$ ]] && continue
        
        # First try direct file existence check
        found_path=$(file_exists "$file_path")
        if [ $? -eq 0 ]; then
            echo "" >> "$OUTPUT_FILE"
            echo "<file>${found_path}</file>" >> "$OUTPUT_FILE"
            cat "$found_path" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            echo "Found file: $found_path"
        else
            # If not found directly, try fuzzy search
            echo "File not found directly, trying fuzzy search for: $file_path"
            found_path=$(find_file_fuzzy "$file_path")
            if [ $? -eq 0 ]; then
                echo "" >> "$OUTPUT_FILE"
                echo "<file>${found_path}</file>" >> "$OUTPUT_FILE"
                cat "$found_path" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
                echo "Found file via fuzzy search: $found_path"
            else
                echo "Warning: File not found: $file_path" >&2
            fi
        fi
    done < "scripts.txt"

    echo "" >> "$OUTPUT_FILE"
    echo "</potential_codebase_context>" >> "$OUTPUT_FILE"

    echo "Context file generated as $OUTPUT_FILE"
}

# Main execution
echo "Starting script execution..."

# Create scripts.txt if it doesn't exist
if [ ! -f "scripts.txt" ]; then
    touch "scripts.txt"
    echo "Created new scripts.txt file"
fi

# Open scripts.txt in nvim for editing
echo "Opening scripts.txt in nvim. Add file paths, one per line."
echo "Press :wq to save and exit when done."
nvim "scripts.txt"

# Check if scripts.txt has content
if [ -s "scripts.txt" ]; then
    echo "Processing files in scripts.txt..."
    generate_context
    echo "Done! Context has been generated in llm_context.txt"
else
    echo "scripts.txt is empty. No files to process."
    exit 1
fi 