#!/bin/bash -e

KEYCLOAK_URL="https://sso.local.io:32443"
KC_USERNAME="admin"
KC_PASSWORD=""
WRONG_KC_PASSWORD=""
GRAFANA_CLIENT="grafana"
ARGOCD_CLIENT="argocd"
ARGOWF_CLIENT="argowf"
GRAFANA_CLIENT_SECRET=""
WRONG_GRAFANA_CLIENT_SECRET=""
ARGOCD_CLIENT_SECRET=""
WRONG_ARGOCD_CLIENT_SECRET=""
ARGOWF_CLIENT_SECRET=""
WRONG_ARGOWF_CLIENT_SECRET=""

# Maste Realm Login with admin-cli
function login_master() {
    echo "Logging to Master realm with username and password"
    while true; do curl -s -k -X POST "https://sso.local.io:32443/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" \
    -d "username=$KC_USERNAME" \
    -d "password=$KC_PASSWORD" | jq -r '.access_token' | cut -d '.' -f2 | base64 -d | jq . && sleep 3s; done
}

function wrong_login_master() {
    echo "Logging to Master realm with username and password"
    while true; do curl -s -k -X POST "https://sso.local.io:32443/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" \
    -d "username=$KC_USERNAME" \
    -d "password=$WRONG_KC_PASSWORD" | jq -r '.access_token' && sleep 3s; done
}

# Platform Realm with argocd client
function argocd_platform() {
    echo "Logging to ArgoCD in Platform Realm"
    while true; do curl -s -k -X POST "https://sso.local.io:32443/realms/platform/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$ARGOCD_CLIENT" \
    -d "client_secret=$ARGOCD_CLIENT_SECRET" \
    -d "username=bob" \
    -d "password=hello" | jq -r '.access_token' | cut -d '.' -f2 | base64 -d | jq . && sleep 3s; done
}

function wrong_argocd_platform() {
    echo "Logging to ArgoCD in Platform Realm"
    while true; do curl -s -k -X POST "https://sso.local.io:32443/realms/platform/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$ARGOCD_CLIENT" \
    -d "client_secret=$WRONG_ARGOCD_CLIENT_SECRET" \
    -d "username=bob" \
    -d "password=hello" | jq -r '.access_token' && sleep 3s; done
}

# App Realm with ArgoWF client
function argowf_app() {
    echo "Logging to Argo-Workflows in Data Realm"
    while true; do curl -sk -XPOST "https://sso.local.io:32443/realms/app/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$ARGOWF_CLIENT" \
    -d "client_secret=$ARGOWF_CLIENT_SECRET" \
    -d "username=bobwf" \
    -d "password=hello" | jq -r '.access_token' | cut -d '.' -f2 | base64 -d | jq . && sleep 3s; done
}

function wrong_argowf_app() {
    echo "Logging to Argo-Workflows in Data Realm"
    while true; do curl -sk -XPOST "https://sso.local.io:32443/realms/app/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$ARGOWF_CLIENT" \
    -d "client_secret=$WRONG_ARGOWF_CLIENT_SECRET" \
    -d "username=bob" \
    -d "password=hello" | jq -r '.access_token' && sleep 3s; done
}

# Data Realm with Grafana client
function grafana_data() {
    echo "Logging to Grafana in Master Realm"
    while true; do curl -s -k -X POST "https://sso.local.io:32443/realms/data/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$GRAFANA_CLIENT" \
    -d "client_secret=$GRAFANA_CLIENT_SECRET" \
    -d "username=grafana_user1" \
    -d "password=hello" | jq -r '.access_token' | cut -d '.' -f2 | base64 -d | jq . && sleep 3s; done
}

function wrong_grafana_data() {
    echo "Logging to Grafana in Master Realm"
    while true; do curl -s -k -X POST "https://sso.local.io:32443/realms/data/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$GRAFANA_CLIENT" \
    -d "client_secret=$WRONG_GRAFANA_CLIENT_SECRET" \
    -d "username=bob" \
    -d "password=hello" | jq -r '.access_token' && sleep 3s; done
}

while true; do
    echo "Choose a site to hit:"
    echo "1) ArgoCD in Platform Realm"
    echo "2) Grafana in Master Realm"
    echo "3) Argo WF in Data Realm"
    echo "4) Login to Master Realm"
    echo "5) Wrong Login to ArgoCD in Platform Realm"
    echo "6) Wrong Login to Grafana in Master Realm"
    echo "7) Wrong Login to Argo WF in Data Realm"
    echo "8) Wrong Login to Master Realm"
    echo "q) Quit"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            argocd_platform
            ;;
        2)
            grafana_data
            ;;
        3)
            argowf_app
            ;;
        4)
            login_master
            ;;
        5)
            wrong_argocd_platform
            ;;
        6)
            wrong_grafana_data
            ;;
        7)
            wrong_argowf_app
            ;;
        8)
            wrong_login_master
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
