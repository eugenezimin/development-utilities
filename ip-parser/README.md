# IP Parser & WHOIS Reporter

A Zsh utility for extracting public IPv4 addresses from log files, enriching them via WHOIS lookup, filtering by country, and aggregating them into /24 subnets.

## Features

- **IP Extraction** - Parses log files to find valid public IPv4 addresses with automatic validation of octets
- **WHOIS Enrichment** - Performs WHOIS lookups to retrieve organization, country, netname, and CIDR information
- **Country Filtering** - Filter results by country codes (e.g., RU, US, N/A)
- **Subnet Aggregation** - Groups IPs into /24 CIDR blocks with counts
- **Markdown Output** - Generates formatted tables for easy documentation and reporting
- **Automatic Exclusions** - Filters out private IP ranges (192.168.*, 127.*, 0.*)

## Requirements

- Zsh shell
- `whois` command-line utility (standard on macOS)
- `grep`, `awk`, `sort` (standard utilities)

## Installation

The script is ready to use as-is. Make it executable:

```bash
chmod +x ip-parser/whois.sh
```

## Usage

### Basic usage - extract and report all public IPs

```bash
./ip-parser/whois.sh sshuttle.log
```

### Filter by specific countries

```bash
./ip-parser/whois.sh -c RU,US sshuttle.log
```

Include N/A for IPs that could not be resolved:

```bash
./ip-parser/whois.sh -c RU,N/A,US sshuttle.log
```

### Pipe from stdin

```bash
cat sshuttle.log | ./ip-parser/whois.sh -c RU,N/A
```

## Options

- `-c LIST` - Comma-separated country codes to keep (e.g., "RU,N/A,US"). "N/A" matches IPs that whois could not resolve. Omit to keep all IPs.
- `-h` - Display help message

## Output

The script generates two tables in Markdown format:

### 1. Detailed IP Report

A table showing each IP with associated information:

| IP | Org | Country | Netname | CIDR |
|---|---|---|---|---|
| 203.0.113.45 | Example Corp | RU | EXAMPLE-NET | 203.0.113.0/24 |

### 2. /24 Subnet Aggregation

Summary of IPs grouped by /24 CIDR block:

| CIDR | Subnet Mask | IPs |
|---|---|---|
| 203.0.113.0/24 | 255.255.255.0 | 5 |

## Examples

Extract all Russian IPs from an SSH log:

```bash
./ip-parser/whois.sh -c RU /var/log/auth.log
```

Find all unresolved and Russian IPs:

```bash
./ip-parser/whois.sh -c RU,N/A access.log > report.md
```

## Notes

- The script includes a 0.2-second delay between WHOIS requests to be respectful to RIR servers
- IPs are sorted numerically for consistent output
- The script validates IP octets before processing (must be 0-255)
- Private/reserved IP ranges are automatically excluded

## Troubleshooting

**No IPs found:** Verify the log file contains valid IPv4 addresses in standard notation (e.g., 203.0.113.45)

**WHOIS lookup fails:** Some IPs may not be registered in any RIR WHOIS database; these are marked as "N/A" for the country field

**Slow execution:** WHOIS lookups can take time. The script includes progress indicators via stderr

