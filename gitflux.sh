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
    printf "\033[38;5;108m                     Version 1.0.0\n"
    printf "\033[0m\n"
}

# Call the function to test
print_title_with_subtitle




store_account() {
	echo -n "# Enter the username for this account: "
	read -r git_name
	echo -n "# Enter the email address for this account: "
	read -r git_email

	echo "$git_name=$git_email" >> "$CONFIG_FILE"
	echo "# "{$git_name}" successfully added to your list of accounts!"
}

git_name=$(git config --get user.name)
git_email=$(git config --get user.email)

if [ ! -f "$CONFIG_FILE" ]; then
	mkdir -p ~/.config/gitflux
	touch "$CONFIG_FILE"
	echo "# No config file found. Let's set it up!"

	git_name=$(git config --get user.name)
	git_email=$(git config --get user.email)
	
	echo
	echo "# Addded the currently active git account {$git_name} to the gitflux config file."
	echo

	echo "$git_name=$git_email" >> "$CONFIG_FILE"

else
	printf "# Currently active git account on this system is \e[38;5;45m%s\e[0m\n" "${git_name}" 
	echo

fi

switch_account() {
	
	declare -a usernames
	echo -n "# Which account would you like to switch to? "
	echo

	count=1
	while IFS='=' read -r username email; do
		echo "$count] {$username}"
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
			if [ "$username" = "$target_account" ]; then
				ssh-add -D
				ssh-add ~/.ssh/"$target_account"
				git config --global user.name "$target_account"
				git config --global user.email "$value"
				echo "# Successfully switched to account: $target_account"
				return
			fi
		done < "$CONFIG_FILE"
	else
		echo "# {"$target_account"} not among the existing accounts."
	fi
}

add_accounts() {
	store_account
	while true; do
		echo
		echo -n "--> Add another account? (y/n): "
		read -r add_bool
		echo
		if [ "$add_bool" != "y" ]; then
			break
		else
			store_account
		fi
	done
}

delete_account() {

	echo
    list_accounts
    echo

    echo -n "Enter the number of the account to delete: "
    read line_number
    
    sed -i '' "${line_number}d" "$CONFIG_FILE"
	echo
    echo "# Account-"$line_number" deleted successfully!"
}

list_accounts() {
	count=1
	while IFS='=' read -r username email; do
		printf "%s] \033[38;5;201m%s\033[0m : \033[38;5;46m%s\033[0m\n" "$count" "$username" "$email"
		((count++))
	done < $CONFIG_FILE
}

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
            add_accounts
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