#!/bin/bash
# Constitution Compliance Checker v1.0
# Validates Issue/PR against Constitution v1.7.0

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

echo -e "${BLUE}========================================"
echo -e "Constitution Compliance Checker v1.7.0"
echo -e "========================================${NC}\n"

if [ "$1" == "--pr" ]; then
    PR=$2
    echo "Checking PR #$PR..."
    
    DATA=$(gh pr view $PR --json title,body,labels,headRefName,commits)
    TITLE=$(echo "$DATA" | jq -r '.title')
    BODY=$(echo "$DATA" | jq -r '.body // ""')
    LABELS=$(echo "$DATA" | jq -r '.labels | length')
    BRANCH=$(echo "$DATA" | jq -r '.headRefName')
    COMMITS=$(echo "$DATA" | jq -r '.commits | length')
    COMMITS_WITH_ISSUE=$(echo "$DATA" | jq -r '.commits[].messageHeadline' | grep -cE '\[#[0-9]+\]' || echo 0)
    
    echo -e "\n${BLUE}[Principle III]${NC} Issue Reference"
    if echo "$TITLE" | grep -qE '\[#[0-9]+\]'; then
        echo -e "  ${GREEN}✓${NC} Title has issue reference"
        ((PASS++))
    else
        echo -e "  ${RED}✗${NC} Missing issue reference [#N] in title"
        ((FAIL++))
    fi
    
    echo -e "\n${BLUE}[Principle XI]${NC} PR Metadata"
    if [ "$LABELS" -eq 0 ]; then
        echo -e "  ${RED}✗${NC} No labels (must match Issue labels)"
        ((FAIL++))
    else
        echo -e "  ${GREEN}✓${NC} Has $LABELS label(s)"
        ((PASS++))
    fi
    
    if [ ${#BODY} -lt 50 ]; then
        echo -e "  ${RED}✗${NC} Body too short (${#BODY} chars, need 50+)"
        ((FAIL++))
    elif [ ${#BODY} -lt 200 ]; then
        echo -e "  ${YELLOW}⚠${NC} Body brief (${#BODY} chars, recommend 200+)"
        ((WARN++))
    else
        echo -e "  ${GREEN}✓${NC} Body detailed (${#BODY} chars)"
        ((PASS++))
    fi
    
    if echo "$BRANCH" | grep -qE '^(feature|fix|hotfix)/'; then
        echo -e "  ${GREEN}✓${NC} Branch naming: $BRANCH"
        ((PASS++))
    else
        echo -e "  ${YELLOW}⚠${NC} Branch doesn't follow convention: $BRANCH"
        ((WARN++))
    fi
    
    echo -e "\n${BLUE}[Principle XIV]${NC} Commit Synchronization"
    if [ "$COMMITS_WITH_ISSUE" -eq "$COMMITS" ]; then
        echo -e "  ${GREEN}✓${NC} All $COMMITS commit(s) reference issue"
        ((PASS++))
    else
        echo -e "  ${YELLOW}⚠${NC} $COMMITS_WITH_ISSUE/$COMMITS commit(s) reference issue"
        ((WARN++))
    fi
    
elif [ "$1" == "--issue" ]; then
    ISSUE=$2
    echo "Checking Issue #$ISSUE..."
    
    DATA=$(gh issue view $ISSUE --json title,body,labels,milestone)
    TITLE=$(echo "$DATA" | jq -r '.title')
    BODY=$(echo "$DATA" | jq -r '.body // ""')
    LABELS=$(echo "$DATA" | jq -r '.labels | length')
    MILESTONE=$(echo "$DATA" | jq -r '.milestone.title // ""')
    
    echo -e "\n${BLUE}[Principle III]${NC} Issue Metadata"
    if [ "$LABELS" -eq 0 ]; then
        echo -e "  ${RED}✗${NC} No labels assigned"
        ((FAIL++))
    else
        echo -e "  ${GREEN}✓${NC} Has $LABELS label(s)"
        ((PASS++))
    fi
    
    if [ -z "$MILESTONE" ]; then
        echo -e "  ${RED}✗${NC} No milestone assigned"
        ((FAIL++))
    else
        echo -e "  ${GREEN}✓${NC} Milestone: $MILESTONE"
        ((PASS++))
    fi
    
    echo -e "\n${BLUE}[Principle XIII]${NC} Descriptive Title"
    if [ ${#TITLE} -lt 10 ]; then
        echo -e "  ${RED}✗${NC} Title too short (${#TITLE} chars)"
        ((FAIL++))
    else
        echo -e "  ${GREEN}✓${NC} Title length OK (${#TITLE} chars)"
        ((PASS++))
    fi
else
    echo "Usage: $0 --pr <number>  OR  $0 --issue <number>"
    exit 1
fi

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Passed:${NC}  $PASS"
echo -e "${RED}Failed:${NC}  $FAIL"
echo -e "${YELLOW}Warnings:${NC} $WARN"
echo -e "${BLUE}========================================${NC}\n"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ Constitution compliance: PASSED${NC}"
    exit 0
else
    echo -e "${RED}✗ Constitution compliance: FAILED ($FAIL violation(s))${NC}"
    exit 1
fi
