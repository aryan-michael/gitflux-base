#!/bin/bash

CONFIG_FILE=~/.config/gitflux/config

print_title() {
    # Subtle dark purple border
    printf "\033[38;5;98m┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n"
    
    # Metallic gradient with slight purple tint
    printf "\033[38;5;51m  ██████╗ ██╗████████╗███████╗██╗     ██╗   ██╗██╗  ██╗\n"
    printf "\033[38;5;251m ██╔════╝ ██║╚══██╔══╝██╔════╝██║     ██║   ██║╚██╗██╔╝\n"
    printf "\033[38;5;250m ██║  ███╗██║   ██║   █████╗  ██║     ██║   ██║ ╚███╔╝\n"
    printf "\033[38;5;249m ██║   ██║██║   ██║   ██╔══╝  ██║     ██║   ██║ ██╔██╗\n"
    printf "\033[38;5;219m ╚██████╔╝██║   ██║   ██║     ███████╗╚██████╔╝██╔╝ ██╗\n"
    printf "\033[38;5;40m  ╚═════╝ ╚═╝   ╚═╝   ╚═╝     ╚══════╝ ╚═════╝ ╚═╝  ╚═╝\n"
    
    # Subtle dark purple border
    printf "\033[38;5;98m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n"
    
    # Reset color
    printf "\033[0m\n"
}

print_title_with_subtitle() {
    print_title
    # Soft purple subtitle
    printf "\033[38;5;146m         Manage Multiple Git Accounts with Ease\n"
    # Very subtle neon green accent for version
    printf "\033[38;5;108m                     Version 2.0.3\n"
    printf "\033[0m\n"
}

print_title_with_subtitle

setup_account() {
	echo -n "# Enter the username for this account: "
	read -r git_name
	echo -n "# Enter the email address for this account: "
	read -r git_email
	echo

	git config --global user.name "$git_name"
	git config --global user.email "$git_email"

	echo "$git_name=$git_email --active" >> "$CONFIG_FILE"
	echo -e "# \033[38;5;202m$git_name\033[0m successfully added to your list of accounts!"
	echo
}

# Store the git account in the config file
# Does not do anything to the git config 
store_account() {
	echo -n "# Enter the username for this account: "
	read -r git_name
	echo -n "# Enter the email address for this account: "
	read -r git_email
	echo

	echo "$git_name=$git_email" >> "$CONFIG_FILE"
	echo -e "# \033[38;5;202m$git_name\033[0m successfully added to your list of accounts!"
}
# Show the currently active git account
git_name=$(git config --get user.name)
git_email=$(git config --get user.email)

# Mark the account as active in the config file
mark_account_active() {
    target_username="$1"
    temp_file=$(mktemp)
    
    # Create a new config file with the changes
    while IFS='=' read -r username email; do
        # First remove any existing --active flag
        clean_email=${email%% --active}
        
        # Add --active flag only to the target account
        if [ "$username" = "$target_username" ]; then
            echo "$username=$clean_email --active" >> "$temp_file"
        else
            echo "$username=$clean_email" >> "$temp_file"
        fi
    done < "$CONFIG_FILE"
    
    # Replace original with new file
    cat "$temp_file" > "$CONFIG_FILE"
    rm "$temp_file"
}

# Switch to a different git account
# It will move the --active flag to the chosen account
# It will also add the ssh key to the ssh agent if it exists
# It will also change the git config user.name and user.email
switch_account() {
	declare -a usernames
	echo -n "# Which account would you like to switch to? "
	echo

	count=1
	while IFS='=' read -r username email; do
        # Remove --active flag for display purposes
        email=${email%% --active}
        
		echo -e "$count) \033[1;32m$username\033[0m"
		usernames[$count]=$username
		((count++))
	done < "$CONFIG_FILE"

	total=$((count - 1))
	echo
	echo -n "# Enter your choice (1-$total): "
	read -r choice

	if [ "$choice" -ge 1 ] && [ "$choice" -le "$total" ]; then
		target_account=${usernames[$choice]}
		while IFS='=' read -r username email; do
            # Remove --active flag for processing
            email=${email%% --active}
            
			if [ "$username" = "$target_account" ]; then
				ssh-add -D
				ssh-add ~/.ssh/"$target_account"
				git config --global user.name "$target_account"
				git config --global user.email "$email"
                
                # Mark this account as active in the config file
                mark_account_active "$target_account"
                
				echo -e "# Successfully switched to account: \033[1;31m$target_account\033[0m"
				return
			fi
		done < "$CONFIG_FILE"
	else
		echo "# {"$target_account"} not among the existing accounts."
	fi
}

# Add another account to the config file immediately after the first one, this function seems a bit overkill but eh
add_another_account() {
	store_account
	while true; do
		echo
		echo -n "--> Add another account? (y/n): "
		read -r add_bool
		echo
		if [ "$add_bool" != "y" ]; then
			echo "Thank You & Goodbye!"
			break
		else
			store_account
		fi
	done
}

# Delete an account from the config file
# If the account is the currently active one, that account will remain active
# The SSH key will not be removed from the ssh agent
delete_account() {
	echo
    list_accounts
    echo

    echo -n "Enter the number of the account to delete: "
    read line_number
    
    sed -i "${line_number}d" "$CONFIG_FILE"
	echo
    echo -e "# \033[38;5;129mAccount-$line_number\033[0m deleted successfully!"
}

# List all accounts in the config file
# The accounts are listed in the format: username=email
list_accounts() {
	count=1
	while IFS='=' read -r username email; do
        # Check if this account has the --active flag
        if [[ "$email" == *" --active"* ]]; then
            # Remove --active flag for display purposes
            display_email=${email%% --active}
            printf "%s) \033[38;5;201m%s\033[0m : \033[38;5;46m%s\033[0m \033[38;5;220m--active\033[0m\n" "$count" "$username" "$display_email"
        else
            printf "%s) \033[38;5;201m%s\033[0m : \033[38;5;46m%s\033[0m\n" "$count" "$username" "$email"
        fi
		((count++))
	done < "$CONFIG_FILE"
}

# Check if the config file exists, if not create it
# If the config file exists, check if the currently active git account is in the config file
# If the currently active git account is not in the config file, add it to the config file
if [ ! -f "$CONFIG_FILE" ]; then
	mkdir -p ~/.config/gitflux
	touch "$CONFIG_FILE"
	echo "# No config file found. Let's set it up!"

	git_name=$(git config --get user.name)
	git_email=$(git config --get user.email)

	# Check if git_name and git_email are empty
	if [ -z "$git_name" ] || [ -z "$git_email" ]; then
		echo "# No git account found on this system."
		echo
		echo "# Let's add your first account."
		echo
		setup_account
	else
		echo
		printf "# Added the currently active git account \e[38;5;45m%s\e[0m to the gitflux config file.\n" "$git_name"
        echo
		
		echo "$git_name=$git_email --active" >> "$CONFIG_FILE"
	fi

else
	printf "# Currently active git account on this system is \e[38;5;45m%s\e[0m\n" "${git_name}" 
	echo

    # Check if the current git account is in the config file
    # If not, add it and mark it as active
    if [ -n "$git_name" ] && [ -n "$git_email" ]; then
        account_found=false
        while IFS='=' read -r username email; do
            # Remove --active flag for comparison
            clean_email=${email%% --active}
            
            if [ "$username" = "$git_name" ]; then
                account_found=true
                # Ensure this account is marked as active
                mark_account_active "$git_name"
                break
            fi
        done < "$CONFIG_FILE"
        
        # If account not found in config, add it
        if [ "$account_found" = false ]; then
            echo "$git_name=$git_email --active" >> "$CONFIG_FILE"
            echo "# Added the currently active git account {$git_name} to the gitflux config file."
        fi
    fi
fi

while true; do
    echo "# Select an option:"
	echo
    echo "1) Switch to a different account"
    echo "2) Add a new account"
    echo "3) Delete an existing account"
    echo "4) List all available accounts"
    echo "5) Exit"
	echo
    echo -n "# Enter your choice (1-5): "
    read choice
	echo
    
    case $choice in
        1)
            echo "* Switching accounts: "
			echo
            switch_account
			echo
			exit 0
            ;;
        2)
            echo "* Adding a new account: "
			echo
            add_another_account
			echo
			exit 0
            ;;
        3)
            echo "* Choose an account to delete: "
            delete_account
			echo
			exit 0
            ;;
        4)
            echo "# Available accounts: "
            list_accounts
			echo
			exit 0
            ;;
        5)
            echo "-> Goodbye! <-"
            echo
			exit 0
            ;;
        *)
            echo "Invalid option. Please choose 1-5"
            ;;
    esac
    
    echo
done