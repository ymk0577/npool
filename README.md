# Npool
This Npool is a modified non-Npool official NKN mining pool installation script.
The script file comes from the official file, and only some codes are added/modified/deleted according to personal needs to suit personal use needs.

Reference website/document:
1. https://www.npool.io/
2. https://github.com/nknorg/nkn

# Differences from the official script
1. The settings on the system connection number that exist in the official script are unreasonable for most machine configurations, so the adjustment on the number of connections is directly removed and the system default connection number settings are used.
2. Add limit to journald log size and set persistence.
3. Add Syslog file size limit and set persistence.
4. Added Journald to not forward logs to Syslog.
5. Due to its specific purpose, the script disables firewall logging.
6. The commands to install and enable the firewall are removed, but the firewall rules are retained to adapt to needs.

# Notice
Please check the code yourself before use to confirm whether it meets your own usage requirements.
Please note that I am not responsible for any problems that arise from using this script.
