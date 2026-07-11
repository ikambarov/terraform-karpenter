# Client Tracker

This layer contains the environment values for deploying the Client Tracker Django app to the EKS platform.

The app chart is expected to live outside this infra repo. By default, `apply.sh` looks for it in a sibling checkout:

```text
../client_tracker/charts/client-tracker
```

Use `CLIENT_TRACKER_REPO_DIR` or `APP_CHART_DIR` to point at a different chart location.

The tracked values file keeps app settings generic. Set the container image at runtime with `APP_IMAGE_REPOSITORY` and `APP_IMAGE_TAG`, or supply a different values file with `APP_VALUES_FILE`.
