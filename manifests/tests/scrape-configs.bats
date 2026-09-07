#!/usr/bin/env bats

setup() {
  cd "$BATS_TEST_DIRNAME/.."
  RENDERED="$(helm template .)"
  export RENDERED
}

@test "prometheus-config scrape_configs does not include a github-runner-controller job" {
  prometheus_yml=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "ConfigMap" and .metadata.name == "prometheus-config") | .data["prometheus.yml"]
  ' -)

  job_names=$(echo "$prometheus_yml" | yq eval '.scrape_configs[].job_name' -)

  ! echo "$job_names" | grep -q '^github-runner-controller$'
}

@test "prometheus-config scrape_configs does not include a woodpecker job" {
  prometheus_yml=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "ConfigMap" and .metadata.name == "prometheus-config") | .data["prometheus.yml"]
  ' -)

  job_names=$(echo "$prometheus_yml" | yq eval '.scrape_configs[].job_name' -)

  ! echo "$job_names" | grep -q '^woodpecker$'
}

@test "does not render a woodpecker-token secret volume or ExternalSecret" {
  ! echo "$RENDERED" | yq eval-all 'select(.metadata.name == "prometheus-woodpecker-token")' - | grep -q .
}
