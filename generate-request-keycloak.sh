#!/bin/bash -e

# Global variables
KC_URL="http://sso.local.io:32080"
MASTER_REALM="master"
PLATFORM_REALM="platform"
MASTER_USERNAME="admin"
MASTER_PASSWORD="admin123"
MASTER_CLIENT_ID="admin-cli"
WRONG_MASTER_PASSWORD="admin123456"

# ArgoCD Cient ID and Client Secret
ARGOCD_CLIENT="argocd"
ARGOCD_CLIENT_SECRET="lMV6Ped1Eoh3MCiOA1MOtyug2wsKiniT"
WRONG_ARGOCD_CLIENT_SECRET="S97tneAqdp"

# Grafana Client ID and Client Secret
GRAFANA_CLIENT="grafana"
GRAFANA_CLIENT_SECRET="2LMYyV1IfzwgVEWOneYg3Fyaa2JX0F8m"
WRONG_GRAFANA_CLIENT_SECRET="F4PEalwRkNZjyMeEyXCaB"

# Argo Workflow Client ID and Client Secret
ARGOWF_CLIENT="argo-workflow"
ARGOWF_CLIENT_SECRET="G2lKyB5YSapVMFo5uOijSXjAAApSgbKl"
WRONG_ARGOWF_CLIENT_SECRET="G2lKyB5YSapVMFo5uOijSX"

# OAuth2 Proxy Client ID and Client Secret
OAUTH_CLIENT="auth"
OAUTH_CLIENT_SECRET="R1T7eOmbB8GoDblJgFP1NxtsJXGV7vyM"
WRONG_OAUTH_CLIENT_SECRET="R1T7eOmbB8GoDblJgF"

# Vault Client ID and Client Secrets
SECRETS_CLIENT="secrets"
SECRETS_CLIENT_SECRET="hQSD7nFZd3ddIwTdvXundX4Prc9jimTN"
WRONG_SECRETS_CLIENT_SECRET="pY6DCorLYBkve7oJbSOilk"

# Common Username and Password for Client logins
USER_NAME="bob"
USER_PASSWORD="PkiRiXmB9TZ1KcEJ"

# function common_request() {
#     curl -s -XPOST "$KC_URL/realms/$REALM_NAME/protocol/openid-connect/token" \
#     -H "Content-Type: application/x-www-form-urlencoded" \
#     -d "grant_type=password" \
#     -d "client_id=$CLIENT_ID" \
#     -d "client_secret=$CLIENT_SECRET" \
#     -d "username=$USER_NAME" \
#     -d "password=$USER_PASSWORD" | jq -r '.access_token' | cut -d '.' -f2 | base64 -d | jq . && sleep 3s; done
# }

function loop_master_login() {
    echo ""
    echo "Logging to Master realm with username and password with valid credentials."
    echo ""
    while true; do curl -s -XPOST "$KC_URL/realms/$MASTER_REALM/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$MASTER_CLIENT_ID" \
    -d "username=$MASTER_USERNAME" \
    -d "password=$MASTER_PASSWORD" | jq -r '.access_token' | cut -d '.' -f2 | base64 -d | jq . && sleep 3s; done
}

function loop_wrong_master_login() {
    echo ""
    echo "Logging to Master realm with username and password with invalid credentials."
    echo ""
    while true; do curl -s -XPOST "$KC_URL/realms/$MASTER_REALM/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$MASTER_CLIENT_ID" \
    -d "username=$MASTER_USERNAME" \
    -d "password=$WRONG_MASTER_PASSWORD" | jq -r '.access_token' && sleep 3s; done
}

function loop_argocd_login() {
    echo ""
    echo "Logging to ArgoCD in Platform Realm with valid credentials."
    echo ""
    while true; do curl -s -XPOST "$KC_URL/realms/$PLATFORM_REALM/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$ARGOCD_CLIENT" \
    -d "client_secret=$ARGOCD_CLIENT_SECRET" \
    -d "username=$USER_NAME" \
    -d "password=$USER_PASSWORD" | jq -r '.access_token' | cut -d '.' -f2 | base64 -d | jq . && sleep 3s; done
}

function loop_wrong_argocd_login() {
    echo ""
    echo "Logging to ArgoCD in Platform Realm with invalid credentials"
    echo ""
    while true; do curl -s -XPOST "$KC_URL/realms/$PLATFORM_REALM/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$ARGOCD_CLIENT" \
    -d "client_secret=$WRONG_ARGOCD_CLIENT_SECRET" \
    -d "username=$USER_NAME" \
    -d "password=$USER_PASSWORD" | jq -r '.access_token' && sleep 3s; done
}

function loop_argowf_login() {
    echo ""
    echo "Logging to Argo-Workflows in Platform Realm with valid credentials"
    echo ""
    while true; do curl -s -XPOST "$KC_URL/realms/$PLATFORM_REALM/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$ARGOWF_CLIENT" \
    -d "client_secret=$ARGOWF_CLIENT_SECRET" \
    -d "username=$USER_NAME" \
    -d "password=$USER_PASSWORD" | jq -r '.access_token' | cut -d '.' -f2 | base64 -d | jq . && sleep 3s; done
}

function loop_wrong_argowf_login() {
    echo ""
    echo "Logging to Argo-Workflows in Platform Realm with invalid credentials"
    echo ""
    while true; do curl -s -XPOST "$KC_URL/realms/$PLATFORM_REALM/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$ARGOWF_CLIENT" \
    -d "client_secret=$WRONG_ARGOWF_CLIENT_SECRET" \
    -d "username=$USER_NAME" \
    -d "password=$USER_PASSWORD" | jq -r '.access_token' && sleep 3s; done
}

function loop_grafana_login() {
    echo ""
    echo "Logging to Grafana in Platform Realm with valid credentials"
    echo ""
    while true; do curl -s -XPOST "$KC_URL/realms/$PLATFORM_REALM/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$GRAFANA_CLIENT" \
    -d "client_secret=$GRAFANA_CLIENT_SECRET" \
    -d "username=$USER_NAME" \
    -d "password=$USER_PASSWORD" | jq -r '.access_token' | cut -d '.' -f2 | base64 -d | jq . && sleep 3s; done
}

function loop_wrong_grafana_login() {
    echo ""
    echo "Logging to Grafana in Platform Realm with invalid credentials"
    echo ""
    while true; do curl -s -XPOST "$KC_URL/realms/$PLATFORM_REALM/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$GRAFANA_CLIENT" \
    -d "client_secret=$WRONG_GRAFANA_CLIENT_SECRET" \
    -d "username=$USER_NAME" \
    -d "password=$USER_PASSWORD" | jq -r '.access_token' && sleep 3s; done
}

function loop_oauth_login() {
    echo ""
    echo "Logging to OAuth in Platform Realm with valid credentials"
    echo ""
    while true; do curl -s -XPOST "$KC_URL/realms/$PLATFORM_REALM/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$OAUTH_CLIENT" \
    -d "client_secret=$OAUTH_CLIENT_SECRET" \
    -d "username=$USER_NAME" \
    -d "password=$USER_PASSWORD" | jq -r '.access_token' | cut -d '.' -f2 | base64 -d | jq . && sleep 3s; done
}

function loop_wrong_oauth_login() {
    echo ""
    echo "Logging to OAuth in Platform Realm with invalid credentials"
    echo ""
    while true; do curl -s -XPOST "$KC_URL/realms/$PLATFORM_REALM/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$OAUTH_CLIENT" \
    -d "client_secret=$WRONG_OAUTH_CLIENT_SECRET" \
    -d "username=$USER_NAME" \
    -d "password=$USER_PASSWORD" | jq -r '.access_token' && sleep 3s; done
}

function loop_secrets_login() {
    echo ""
    echo "Logging to Secrets Client in Platform Realm with valid credentials"
    echo ""
    while true; do curl -s -XPOST "$KC_URL/realms/$PLATFORM_REALM/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$SECRETS_CLIENT" \
    -d "client_secret=$SECRETS_CLIENT_SECRET" \
    -d "username=$USER_NAME" \
    -d "password=$USER_PASSWORD" | jq -r '.access_token' | cut -d '.' -f2 | base64 -d | jq . && sleep 3s; done
}

function loop_wrong_secrets_login() {
    echo ""
    echo "Logging to Secrets Client in Platform Realm with invalid credentials"
    echo ""
    while true; do curl -s -XPOST "$KC_URL/realms/$PLATFORM_REALM/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$SECRETS_CLIENT" \
    -d "client_secret=$WRONG_SECRETS_CLIENT_SECRET" \
    -d "username=$USER_NAME" \
    -d "password=$USER_PASSWORD" | jq -r '.access_token' && sleep 3s; done
}

function all_hit_random() {
    all_clients=(
        login_master argocd argowf 
        grafana oauth secrets
        wrong_login_master wrong_argocd wrong_grafana
        wrong_argowf wrong_oauth wrong_secrets)
    
    while true; do
        # Pick a random function
        random_index=$((RANDOM % ${#all_clients[@]}))
        selected_client=${all_clients[$random_index]}
        
        echo "===================="
        $selected_client
        echo "===================="

        # Optional: sleep between executions
        sleep 2
    done
}

while true; do
    echo "Choose a site to hit:"
    echo "1) Login to Master Realm"
    echo "2) ArgoCD Client in Platform Realm"
    echo "3) Grafana Client in Platform Realm"
    echo "4) Argo-Workflow Client in Platform Realm"
    echo "5) OAuth2 Client in Platform Realm" 
    echo "6) Secrets Client in Platform Realm"
    echo "7) Wrong Login to Master Realm"
    echo "8) Wrong Login to ArgoCD Client in Platform Realm"
    echo "9) Wrong Login to Grafana Client in Platform Realm"
    echo "10) Wrong Login to Argo Workflow in Platform Realm"
    echo "11) Wrong Login to OAuth2 Client in Platform Realm"
    echo "12) Wrong Login to Secrets Client in Platform Realm"
    echo "13) Randomly hit all clients with Valid and Invalid credentials to Master and Platform Realm"
    echo "q) Quit"
    echo ""
    read -p "Enter your choice: " choice

    case $choice in
        1)
            loop_master_login
            ;;
        2)
            loop_argocd_login
            ;;
        3)
            loop_grafana_login
            ;;
        4)
            loop_argowf_login
            ;;
        5)
            loop_oauth_login
            ;;
        6)
            loop_secrets_login
            ;;
        7)
            loop_wrong_master_login
            ;;
        8)
            loop_wrong_argocd_login
            ;;
        9)
            loop_wrong_grafana_login
            ;;
        10)
            loop_wrong_argowf_login
            ;;
        11)
            loop_wrong_oauth_login
            ;;
        12)
            loop_wrong_secrets_login
            ;;
        13)
            all_hit_random
            ;;
        q|Q)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid option. Try again."
            ;;
    esac
done
