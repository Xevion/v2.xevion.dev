# default to development|dev
ENVIRONMENT="${1:-development}"
if [ "$ENVIRONMENT" = "production"  ]; then
    echo "Building for production"
    bundle exec jekyll build --config _config.yml -t
    exit
elif [ "$ENVIRONMENT" = "development" ]; then
    echo "Building for development"
    bundle exec jekyll serve --config _config.yml,_config_dev.yml -l -t  # Live reload & debug trace
else
    printf "Invalid argument: %s\nValid arguments: dev[elopment]|prod[uction]" "$ENVIRONMENT"
    exit
fi