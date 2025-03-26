{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.tg-notify;
  tg-notify = pkgs.writeShellScriptBin "tg-notify" ''
    #!/bin/bash

    POSITIONAL_ARGS=()

    while [[ $# -gt 0 ]]; do
      case $1 in
        -t)
          title="$2"
          shift # past argument
          shift # past value
          ;;
        -m)
          message="$2"
          shift # past argument
          shift # past value
          ;;
        -*|--*)
          echo "Unknown option $1"
          exit 1
          ;;
        *)
          POSITIONAL_ARGS+=("$1") # save positional arg
          shift # past argument
          ;;
      esac
    done

    declare -a error_messages=(
    "Permanent errors have been detected"
    "UNAVAIL"
    "devices are faulted"
    "DEGRADED"
    "unrecoverable error"
    )

    declare -a warning_patterns=(
    "WARNING"
    "Error"
    "Failed"
    "failure"
    "broken"
    "unsupported"
    )

    # List of warnings that can be safely ignored
    declare -a ignore_patterns=(
    "WARNING: Running .snapraid-btrfs-wrapped as root is not recommended"
    "WARNING! UUID is unsupported for disks"
    "(nor is running snapraid as root)"
    )

    set -- "''${POSITIONAL_ARGS[@]}"

    hostname=$(${pkgs.systemd}/bin/hostnamectl hostname)
    if [[ $title =~ "service" ]]; then
      # Check the actual service status
      SERVICE_NAME="$title"
      EXIT_CODE=$(${pkgs.systemd}/bin/systemctl show -p ExecMainStatus "$SERVICE_NAME" | cut -d= -f2)

      # Get logs regardless to check for warnings
      service_logs=$(${pkgs.systemd}/bin/journalctl --unit=$title -n 20 --no-pager)

      # Check for real warnings (excluding ignorable ones)
      warning_lines=""
      for pattern in "''${warning_patterns[@]}"; do
        # Extract lines containing the warning pattern
        while IFS= read -r line; do
          should_ignore=0
          # Check if this warning should be ignored
          for ignore in "''${ignore_patterns[@]}"; do
            if [[ "$line" == *"$ignore"* ]]; then
              should_ignore=1
              break
            fi
          done

          # Only add non-ignored warnings
          if [ $should_ignore -eq 0 ]; then
            warning_lines+="$line"$'\n'
          fi
        done < <(echo "$service_logs" | grep -i "$pattern" || true)
      done

      if [ "$EXIT_CODE" -eq 0 ]; then
        # Success case
        final_title="✅ Service $title succeeded on $hostname"

        if [ -n "$warning_lines" ]; then
          # Success but with non-ignorable warnings - include just those warning lines
          final_message="$warning_lines"
        else
          # Clean success - no logs needed
          final_message=""
        fi
      else
        # Failure case - always include full logs
        final_title="❌ Service $title failed on $hostname"
        final_message="$service_logs"
      fi
    else
      # Non-service message handling
      emoji="✅"
      for i in "''${error_messages[@]}"; do
        if [[ "$message" == *"$i"* ]]; then
          emoji="❌"
        fi
      done
      final_title="$emoji $title on $hostname"
      final_message=$message
    fi

    # Only add the code block if there's a message to display
    if [ -n "$final_message" ]; then
      text="
      <b>$final_title</b>

      <code>$final_message</code>
      "
    else
      text="<b>$final_title</b>"
    fi

    /run/current-system/sw/bin/curl --data "chat_id=$CHANNEL_ID" \
            --data-urlencode "text=$text" \
            --data-urlencode "parse_mode=HTML" \
            https://api.telegram.org/$API_KEY/sendMessage
  '';
in {
  options.tg-notify = {
    enable = lib.mkEnableOption {
      description = "Send a Telegram notification on service failure";
    };
    credentialsFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file with the Telegram API key and channel ID";
      example = lib.literalExpression ''
        pkgs.writeText "telegram-credentials" '''
          API_KEY=secret
          CHANNEL_ID=secret
        '''
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."tg-notify@" = {
      description = "Send a Telegram notification on service failure";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe tg-notify} -t %i.service";
        EnvironmentFile = cfg.credentialsFile;
      };
    };
    environment.systemPackages = [tg-notify];
  };
}
