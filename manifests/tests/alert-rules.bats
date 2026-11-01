#!/usr/bin/env bats

setup() {
  cd "$BATS_TEST_DIRNAME/.."
  RENDERED="$(helm template .)"
  export RENDERED
}

@test "prometheus-alerts includes a PiUpdatesAvailable rule" {
  alerts_yml=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "ConfigMap" and .metadata.name == "prometheus-alerts") | .data["alerts.yml"]
  ' -)

  rule=$(echo "$alerts_yml" | yq eval '.groups[].rules[] | select(.alert == "PiUpdatesAvailable")' -)

  [ -n "$rule" ]

  expr=$(echo "$rule" | yq eval '.expr' -)
  [ "$expr" = "node_apt_upgrades_pending > 0" ]

  for_duration=$(echo "$rule" | yq eval '.for' -)
  [ "$for_duration" = "5m" ]

  severity=$(echo "$rule" | yq eval '.labels.severity' -)
  [ "$severity" = "warning" ]

  summary=$(echo "$rule" | yq eval '.annotations.summary' -)
  [ "$summary" = '{{ $labels.pi }} has {{ $value }} package update(s) available' ]
}

@test "prometheus-alerts SlowInternetSpeed rule ignores the exporter's zero placeholder reading" {
  alerts_yml=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "ConfigMap" and .metadata.name == "prometheus-alerts") | .data["alerts.yml"]
  ' -)

  rule=$(echo "$alerts_yml" | yq eval '.groups[].rules[] | select(.alert == "SlowInternetSpeed")' -)

  [ -n "$rule" ]

  expr=$(echo "$rule" | yq eval '.expr' -)
  [ "$expr" = "speedtest_download_bits_per_second > 0 and speedtest_download_bits_per_second < 50000000" ]

  for_duration=$(echo "$rule" | yq eval '.for' -)
  [ "$for_duration" = "5m" ]

  severity=$(echo "$rule" | yq eval '.labels.severity' -)
  [ "$severity" = "warning" ]
}
