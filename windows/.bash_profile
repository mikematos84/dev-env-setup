# Read .env files
ENV_FILE=".env*"
if ls $ENV_FILE 1> /dev/null 2>&1; then
    export $(grep -v '^#' $ENV_FILE | xargs)
fi