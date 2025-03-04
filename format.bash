#!/bin/bash

# Check if fzf is installed
check_fzf_installed() {
    if ! command -v fzf >/dev/null 2>&1; then
        echo "Error: fzf is not installed. Please install it with 'sudo apt install fzf' or equivalent."
        exit 1
    fi
}

# Function to clear scripts list file only
clear_scripts_file() {
    > "scripts.txt"
    echo "Scripts file cleared."
}

# Function to check if file exists
file_exists() {
    local file_path="$1"
    
    # Special case for input.svelte (check this first)
    if [[ "$file_path" == *"input.svelte"* ]]; then
        if [[ -f "/home/aj/dev/study/frontend/src/lib/utils/popups/input.svelte" ]]; then
            echo "/home/aj/dev/study/frontend/src/lib/utils/popups/input.svelte"
            return 0
        elif [[ -f "/home/aj/dev/actions-runner/_work/study/study/frontend/src/lib/utils/popups/input.svelte" ]]; then
            echo "/home/aj/dev/actions-runner/_work/study/study/frontend/src/lib/utils/popups/input.svelte"
            return 0
        fi
    fi
    
    # Check if file exists either as absolute path or relative to current directory
    if [[ -f "$file_path" ]]; then
        echo "$file_path" # Return the path as is
        return 0
    # Check if file exists relative to parent directory
    elif [[ -f "../$file_path" ]]; then
        echo "../$file_path" # Return the correct path
        return 0
    # Check if file exists in study directory (common location in your setup)
    elif [[ -f "/home/aj/dev/study/$file_path" ]]; then
        echo "/home/aj/dev/study/$file_path" # Return the correct path
        return 0
    # Check if file exists in frontend/src directory (specific to your setup)
    elif [[ -f "/home/aj/dev/study/frontend/src/$file_path" ]]; then
        echo "/home/aj/dev/study/frontend/src/$file_path" # Return the correct path
        return 0
    # Check if file exists in actions-runner directory (another location in your setup)
    elif [[ -f "/home/aj/dev/actions-runner/_work/study/study/$file_path" ]]; then
        echo "/home/aj/dev/actions-runner/_work/study/study/$file_path" # Return the correct path
        return 0
    # Check if file exists in actions-runner frontend/src directory
    elif [[ -f "/home/aj/dev/actions-runner/_work/study/study/frontend/src/$file_path" ]]; then
        echo "/home/aj/dev/actions-runner/_work/study/study/frontend/src/$file_path" # Return the correct path
        return 0
    # Special case for lib/utils/popups/input.svelte
    elif [[ "$file_path" == "lib/utils/popups/input.svelte" ]]; then
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

# Function to display and edit the script list
edit_script_list() {
    check_fzf_installed

    local temp_file=$(mktemp)
    echo "Created temporary file: $temp_file"
    
    # Create debug files
    echo "Starting debug log" > /tmp/format_debug.log
    echo "Temporary file: $temp_file" >> /tmp/format_debug.log
    
    # Ensure there's at least one entry for fzf to show
    echo "# Add files with ctrl-i, delete with ctrl-d, navigate with arrows" > "$temp_file"
    
    if [ -f "scripts.txt" ] && [ -s "scripts.txt" ]; then
        cat "scripts.txt" >> "$temp_file"
        echo "Loaded existing scripts from scripts.txt" | tee -a /tmp/format_debug.log
    else
        echo "No existing scripts found or file is empty" | tee -a /tmp/format_debug.log
    fi

    echo "Starting fzf interface..." | tee -a /tmp/format_debug.log
    # Open temp file in fzf with enhanced keybindings
    query_result=$(cat "$temp_file" | fzf \
        --preview '
            if [[ -s /tmp/fuzzy_results && -n "{q}" && ! "{}" =~ ^# ]]; then
                echo "Fuzzy matches for: {q}";
                echo "------------------------";
                cat /tmp/fuzzy_display;
                echo "";
                echo "Debug info:";
                cat /tmp/fuzzy_debug 2>/dev/null || echo "No debug info available";
            elif [ -f {} ]; then 
                cat {}; 
            elif [ -f "../{}" ]; then 
                cat "../{}"; 
            else 
                echo "File not found or is a comment"; 
                if [[ -n "{q}" ]]; then
                    echo "";
                    echo "Try typing more characters to search for files";
                    echo "Current query: {q}";
                fi;
            fi
        ' \
        --bind 'up:up' \
        --bind 'down:down' \
        --bind 'ctrl-d:execute(sed -i "/{}/d" '"$temp_file"' && cat '"$temp_file"')' \
        --bind 'ctrl-i:execute(find .. -type f | grep -v "node_modules" | grep -v ".git" | fzf --preview "cat {}" >> '"$temp_file"' && sort '"$temp_file"' | uniq > '"$temp_file"'.sorted && mv '"$temp_file"'.sorted '"$temp_file"' && cat '"$temp_file"')' \
        --bind 'enter:execute(
            selected="{+}";
            query="{q}";
            
            echo "Enter pressed with query: $query, selected: $selected" >> /tmp/format_debug.log;
            
            # Process selection
            if [[ -n "$selected" && ! "$selected" =~ ^#.*$ ]]; then
                # Selected item is a valid file
                if [[ -f "$selected" || -f "../$selected" ]]; then
                    if [[ -f "../$selected" ]]; then 
                        selected="../$selected"; 
                    fi;
                    echo "$selected" >> '"$temp_file"';
                    echo "Added selected file: $selected" >&2;
                    echo "Added selected file: $selected" >> /tmp/format_debug.log;
                fi;
            elif [[ -s /tmp/fuzzy_results ]]; then
                # Use top fuzzy result
                found_file=$(head -1 /tmp/fuzzy_results);
                if [[ -n "$found_file" ]]; then
                    echo "$found_file" >> '"$temp_file"';
                    echo "Added top fuzzy result: $found_file" >&2;
                    echo "Added top fuzzy result: $found_file" >> /tmp/format_debug.log;
                fi;
            elif [[ -n "$query" ]]; then
                # Try exact match
                if [[ -f "$query" || -f "../$query" ]]; then
                    if [[ -f "../$query" ]]; then 
                        query="../$query"; 
                    fi;
                    echo "$query" >> '"$temp_file"';
                    echo "Added exact match: $query" >&2;
                else
                    # Try broader search
                    found_file=$(find .. -type f -name "*$(basename "$query")*" | grep -v "node_modules" | grep -v ".git" | head -1);
                    if [[ -n "$found_file" ]]; then
                        echo "$found_file" >> '"$temp_file"';
                        echo "Added found file: $found_file" >&2;
                    elif [[ "$query" == *"input"* || "$query" == *"svelte"* ]]; then
                        # Special case for input.svelte
                        if [[ -f "/home/aj/dev/study/frontend/src/lib/utils/popups/input.svelte" ]]; then
                            echo "/home/aj/dev/study/frontend/src/lib/utils/popups/input.svelte" >> '"$temp_file"';
                            echo "Added special case: input.svelte" >&2;
                        elif [[ -f "/home/aj/dev/actions-runner/_work/study/study/frontend/src/lib/utils/popups/input.svelte" ]]; then
                            echo "/home/aj/dev/actions-runner/_work/study/study/frontend/src/lib/utils/popups/input.svelte" >> '"$temp_file"';
                            echo "Added special case: input.svelte" >&2;
                        else
                            echo "# Warning: File not found: $query" >> '"$temp_file"';
                        fi;
                    else
                        echo "# Warning: File not found: $query" >> '"$temp_file"';
                    fi;
                fi;
            fi;
            
            # Sort and deduplicate
            sort '"$temp_file"' | uniq > '"$temp_file"'.sorted;
            mv '"$temp_file"'.sorted '"$temp_file"';
            cat '"$temp_file"';
        )' \
        --bind 'ctrl-s:accept' \
        --bind 'ctrl-n:execute(> "scripts.txt" && echo "Scripts file cleared." && cat '"$temp_file"')' \
        --bind 'change:execute-silent(
            query="{q}";
            echo "Change event triggered with query: $query" >> /tmp/format_debug.log;
            if [[ -n "$query" && ${#query} -gt 1 ]]; then
                # Clear previous results
                > /tmp/fuzzy_results;
                > /tmp/fuzzy_display;
                
                # Debug info
                echo "Searching for: $query" > /tmp/fuzzy_debug;
                echo "Searching for: $query" >> /tmp/format_debug.log;
                
                # Search in current and parent directories first - use simpler pattern
                find . .. -type f -name "*${query}*" 2>/dev/null | grep -v "node_modules" | grep -v ".git" > /tmp/fuzzy_results_local;
                echo "Local results count: $(wc -l < /tmp/fuzzy_results_local)" >> /tmp/fuzzy_debug;
                
                # If no results, try case-insensitive search
                if [[ ! -s /tmp/fuzzy_results_local ]]; then
                    query_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]');
                    find . .. -type f -iname "*${query}*" 2>/dev/null | grep -v "node_modules" | grep -v ".git" >> /tmp/fuzzy_results_local;
                    echo "Local case-insensitive results count: $(wc -l < /tmp/fuzzy_results_local)" >> /tmp/fuzzy_debug;
                fi;
                
                # If we have local results, use them
                if [[ -s /tmp/fuzzy_results_local ]]; then
                    cat /tmp/fuzzy_results_local > /tmp/fuzzy_results;
                # Otherwise, search in study directory with more flexible pattern
                else
                    # Try a more flexible search pattern
                    find /home/aj/dev/study -type f -name "*${query}*" 2>/dev/null | grep -v "node_modules" | grep -v ".git" | head -10 > /tmp/fuzzy_results;
                    echo "Study dir results count: $(wc -l < /tmp/fuzzy_results)" >> /tmp/fuzzy_debug;
                    
                    # If no results, try case-insensitive search
                    if [[ ! -s /tmp/fuzzy_results ]]; then
                        find /home/aj/dev/study -type f -iname "*${query}*" 2>/dev/null | grep -v "node_modules" | grep -v ".git" | head -10 > /tmp/fuzzy_results;
                        echo "Study dir case-insensitive results count: $(wc -l < /tmp/fuzzy_results)" >> /tmp/fuzzy_debug;
                    fi;
                    
                    # If still no results, try content search
                    if [[ ! -s /tmp/fuzzy_results ]]; then
                        # Convert query to lowercase for case-insensitive search
                        query_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]');
                        find /home/aj/dev/study -type f -exec grep -l "$query_lower" {} \; 2>/dev/null | grep -v "node_modules" | grep -v ".git" | head -10 >> /tmp/fuzzy_results;
                        echo "Content search results count: $(wc -l < /tmp/fuzzy_results)" >> /tmp/fuzzy_debug;
                    fi;
                    
                    # If still no results, try searching in actions-runner directory
                    if [[ ! -s /tmp/fuzzy_results ]]; then
                        find /home/aj/dev/actions-runner/_work/study/study -type f -name "*${query}*" 2>/dev/null | grep -v "node_modules" | grep -v ".git" | head -10 >> /tmp/fuzzy_results;
                        echo "Actions runner results count: $(wc -l < /tmp/fuzzy_results)" >> /tmp/fuzzy_debug;
                    fi;
                    
                    # Special case for input.svelte
                    if [[ "$query" == *"input"* || "$query" == *"svelte"* ]]; then
                        if [[ -f "/home/aj/dev/study/frontend/src/lib/utils/popups/input.svelte" ]]; then
                            echo "/home/aj/dev/study/frontend/src/lib/utils/popups/input.svelte" >> /tmp/fuzzy_results;
                            echo "Added special case for input.svelte" >> /tmp/fuzzy_debug;
                        elif [[ -f "/home/aj/dev/actions-runner/_work/study/study/frontend/src/lib/utils/popups/input.svelte" ]]; then
                            echo "/home/aj/dev/actions-runner/_work/study/study/frontend/src/lib/utils/popups/input.svelte" >> /tmp/fuzzy_results;
                            echo "Added special case for input.svelte from actions-runner" >> /tmp/fuzzy_debug;
                        fi;
                    fi;
                    
                    # Add common files based on query
                    if [[ ! -s /tmp/fuzzy_results ]]; then
                        # Try to find common files based on partial matches
                        if [[ "$query" == *"format"* || "$query" == *"bash"* ]]; then
                            if [[ -f "./format.bash" ]]; then
                                echo "./format.bash" >> /tmp/fuzzy_results;
                                echo "Added common file: format.bash" >> /tmp/fuzzy_debug;
                            fi;
                        fi;
                        
                        if [[ "$query" == *"script"* || "$query" == *"txt"* ]]; then
                            if [[ -f "./scripts.txt" ]]; then
                                echo "./scripts.txt" >> /tmp/fuzzy_results;
                                echo "Added common file: scripts.txt" >> /tmp/fuzzy_debug;
                            fi;
                        fi;
                        
                        if [[ "$query" == *"context"* || "$query" == *"llm"* ]]; then
                            if [[ -f "./llm_context.txt" ]]; then
                                echo "./llm_context.txt" >> /tmp/fuzzy_results;
                                echo "Added common file: llm_context.txt" >> /tmp/fuzzy_debug;
                            fi;
                        fi;
                    fi;
                fi;
                
                # Display results
                if [[ -s /tmp/fuzzy_results ]]; then
                    echo "Search results for: $query" > /tmp/fuzzy_display;
                    echo "------------------------" >> /tmp/fuzzy_display;
                    head -5 /tmp/fuzzy_results >> /tmp/fuzzy_display;
                    total_count=$(wc -l < /tmp/fuzzy_results);
                    if [[ $total_count -gt 5 ]]; then
                        echo "... and $(($total_count - 5)) more results" >> /tmp/fuzzy_display;
                    fi;
                else
                    echo "No results found for: $query" > /tmp/fuzzy_display;
                    echo "Debug info:" >> /tmp/fuzzy_display;
                    cat /tmp/fuzzy_debug >> /tmp/fuzzy_display;
                fi;
            fi;
        )' \
        --print-query \
        --header $'CONTROLS:\n up/down: navigate\n enter: add top fuzzy search result\n ctrl-d: delete entry\n ctrl-i: insert new file\n ctrl-s: save and exit\n ctrl-n: clear scripts list' \
        --layout=reverse \
        --border \
        --no-multi \
        --ansi \
        --select-1)
    
    echo "FZF selection completed"
    echo "FZF selection completed" >> /tmp/format_debug.log

    # Parse results - first line is the query, second is the selection
    query=$(echo "$query_result" | head -1)
    selected=$(echo "$query_result" | tail -n +2)
    
    echo "Query result: $query_result" >> /tmp/format_debug.log
    echo "Parsed query: $query" >> /tmp/format_debug.log
    echo "Parsed selected: $selected" >> /tmp/format_debug.log

    # Save the result back to scripts.txt, filtering out comments
    if [ -n "$selected" ] || [ -n "$query" ]; then
        grep -v "^#" "$temp_file" > "scripts.txt"
        echo "Saved selection to scripts.txt"
        echo "Saved selection to scripts.txt" >> /tmp/format_debug.log
    else
        echo "No selection made, saving all files except comments"
        echo "No selection made, saving all files except comments" >> /tmp/format_debug.log
        grep -v "^#" "$temp_file" > "scripts.txt"
    fi
    
    rm "$temp_file"
    echo "Removed temporary file"
    echo "Removed temporary file" >> /tmp/format_debug.log
    
    # Show the contents of scripts.txt for debugging
    echo "Contents of scripts.txt:" >> /tmp/format_debug.log
    cat "scripts.txt" >> /tmp/format_debug.log
}

generate_context() {
    OUTPUT_FILE="llm_context.txt"
    # Clear the context file at the beginning of query submission
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
        
        # Use our enhanced file_exists function to find the file
        found_path=$(file_exists "$file_path")
        if [ $? -eq 0 ]; then
            echo "" >> "$OUTPUT_FILE"
            echo "<file>${found_path}</file>" >> "$OUTPUT_FILE"
            cat "$found_path" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        else
            echo "Warning: File not found: $file_path" >&2
        fi
    done < "scripts.txt"

    echo "" >> "$OUTPUT_FILE"
    echo "</potential_codebase_context>" >> "$OUTPUT_FILE"

    echo "Context file generated as $OUTPUT_FILE"
}

# Main execution
echo "Starting script execution..."
edit_script_list
if [ -f "scripts.txt" ]; then
    generate_context
else
    echo "Operation cancelled. No files selected."
    exit 1
fi