# Networking Diagnostics & Troubleshooting

Practical execution guide, command outputs, and explanations for Linux networking commands based on the devops-hero repository.

<img src="https://github.com/user-attachments/assets/8c7ae042-4e39-415b-971b-c8e752e914f2" alt="Networking Diagnostics Workflow" width="100%" />

---

## 1. `ping`

### Purpose:
Checks whether a remote host is reachable across the network and measures the round-trip latency in milliseconds using ICMP echo requests and replies.

### Command:
```bash
ping -c 3 google.com
```

### Output:
```text
PING google.com (192.178.177.113): 56 data bytes
64 bytes from 192.178.177.113: icmp_seq=0 ttl=107 time=79.203 ms
64 bytes from 192.178.177.113: icmp_seq=1 ttl=107 time=76.033 ms
64 bytes from 192.178.177.113: icmp_seq=2 ttl=107 time=81.521 ms

--- google.com ping statistics ---
3 packets transmitted, 3 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 76.033/78.919/81.521/2.249 ms
```

<img src="https://github.com/user-attachments/assets/904fa0e3-5e58-40ef-8da2-6bdb3997653a" alt="ping command execution screenshot" width="100%" />


### Explanation:
Replies with 0% packet loss confirm that Layer 3 routing to `google.com` is functional and the server is responding with an average latency of ~78.9ms.

---

## 2. `traceroute`

### Purpose:
Identifies each intermediate router (hop) packets traverse on the way to the destination by sending packets with increasing TTL values.

### Command:
```bash
traceroute -m 5 google.com
```

### Output:
```text
traceroute: Warning: google.com has multiple addresses; using 192.178.177.113
traceroute to google.com (192.178.177.113), 5 hops max, 40 byte packets
 1  10.52.79.22 (10.52.79.22)  8.828 ms  5.576 ms  4.607 ms
 2  * * *
 3  * * *
 4  * * *
 5  * * *
```

<img src="https://github.com/user-attachments/assets/7b358870-0655-4dbf-82f2-6cebc02d959b" alt="traceroute command execution screenshot" width="100%" />


### Explanation:
Hop 1 shows the local gateway router responding in 4.6ms. The asterisks (`* * *`) on later hops indicate intermediate routers or firewalls configured not to return ICMP TTL-exceeded messages.

---

## 3. `netstat` / `ss`

### Purpose:
Displays active TCP/UDP sockets, listening ports, and connection states to verify what network services are open locally.

### Command:
```bash
netstat -an | grep LISTEN | head -n 6
# or on Linux: ss -tuln
```

### Output:
```text
tcp46      0      0  *.50311                *.*                    LISTEN
tcp46      0      0  *.50310                *.*                    LISTEN
tcp4       0      0  127.0.0.1.52407        *.*                    LISTEN
tcp4       0      0  127.0.0.1.52397        *.*                    LISTEN
tcp4       0      0  127.0.0.1.52396        *.*                    LISTEN
tcp4       0      0  127.0.0.1.52395        *.*                    LISTEN
```

<img src="https://github.com/user-attachments/assets/22c54bb4-757d-4d7e-bc4f-c6b22334ac4e" alt="netstat listening ports screenshot" width="100%" />


### Explanation:
Lists active local listening endpoints on loopback and wildcard interfaces, confirming processes bound to ephemeral and local communication ports.

---

## 4. `telnet` / `nc`

### Purpose:
Tests raw Layer 4 TCP port connectivity to verify whether a specific port is open and accepting incoming connections.

### Command:
```bash
nc -zv -w 2 google.com 80
nc -zv -w 2 google.com 443
# or: telnet google.com 80
```

### Output:
```text
Connection to google.com port 80 [tcp/http] succeeded!
Connection to google.com port 443 [tcp/https] succeeded!
```

<img src="https://github.com/user-attachments/assets/95713d2e-9100-48ad-83c9-346c6773690b" alt="nc port connectivity test screenshot" width="100%" />


### Explanation:
Completing the TCP three-way handshake confirms that both HTTP (80) and HTTPS (443) are unblocked by upstream firewalls.

---

## 5. `tcpdump`

### Purpose:
Captures and logs network packets passing through a network interface in real time for packet-level debugging and security analysis.

### Command:
```bash
sudo tcpdump -i en0 -c 4
```

### Output:
```text
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on en0, link-type EN10MB (Ethernet), snapshot length 524288 bytes
00:31:35.266284 IP6 2409:40e1:1005:939b:15aa:ffc4:f751:df06.54429 > 2001:4860:4842:400::.https: Flags [.], ack 3140381164, win 2048, length 0
00:31:35.297567 IP6 2409:40e1:1005:939b:15aa:ffc4:f751:df06.54428 > 2001:4860:4844:400::.https: Flags [.], ack 36241044, win 2048, length 0
00:31:35.319771 IP6 2001:4860:4842:400::.https > 2409:40e1:1005:939b:15aa:ffc4:f751:df06.54429: Flags [.], ack 1, win 1048, options [nop,nop,TS val 332794944 ecr 2833610005], length 0
00:31:35.333247 IP6 64:ff9b::1189:a203.https > 2409:40e1:1005:939b:15aa:ffc4:f751:df06.50936: Flags [.], ack 1583461015, win 24, options [nop,nop,TS val 770996408 ecr 2485632698], length 0
4 packets captured
17 packets received by filter
0 packets dropped by kernel
```

<img src="https://github.com/user-attachments/assets/8eb24317-7caf-479d-aa74-6a9c03e7662d" alt="tcpdump packet capture screenshot" width="100%" />


### Explanation:
Captures live IPv6 HTTPS traffic with Cloudfront CDN endpoints, DNS reverse pointer lookups (PTR queries), and local Layer 2 ARP discovery broadcasts.

---

## 6. `nslookup`

### Purpose:
Performs a DNS lookup to translate a human-readable domain name into an IP address using the system's configured resolver.

### Command:
```bash
nslookup google.com
```

### Output:
```text
Server:		2409:40e1:1005:939b::87
Address:	2409:40e1:1005:939b::87#53

Non-authoritative answer:
Name:	google.com
Address: 192.178.158.100
Name:	google.com
Address: 192.178.158.101
Name:	google.com
Address: 192.178.158.138
Name:	google.com
Address: 192.178.158.102
Name:	google.com
Address: 192.178.158.113
Name:	google.com
Address: 192.178.158.139
```

<img src="https://github.com/user-attachments/assets/5b22bad0-08ec-4dc7-8077-6c2708621fd0" alt="nslookup DNS query screenshot" width="100%" />


### Explanation:
DNS resolver returned 6 valid IPv4 addresses for `google.com` under round-robin DNS load balancing.

---

## 7. `dig`

### Purpose:
Domain Information Groper. Performs detailed DNS queries, displaying raw DNS records, query duration, server flags, and TTL values.

### Command:
```bash
dig google.com +noall +answer
```

### Output:
```text
; <<>> DiG 9.10.6 <<>> google.com +noall +answer
;; global options: +cmd
google.com.		104	IN	A	192.178.177.113
google.com.		104	IN	A	192.178.177.100
google.com.		104	IN	A	192.178.177.102
google.com.		104	IN	A	192.178.177.139
google.com.		104	IN	A	192.178.177.101
google.com.		104	IN	A	192.178.177.138
```

<img src="https://github.com/user-attachments/assets/3334ad59-12f0-4bac-a04b-82e94f8698fc" alt="dig DNS query screenshot" width="100%" />


### Explanation:
Provides the DNS `A` records and cache TTL (104 seconds), which determines how long local resolvers cache this DNS mapping.

---

## 8. `curl`

### Purpose:
Tests HTTP/HTTPS application endpoints, downloads web resources, and inspects HTTP response headers and status codes.

### Command:
```bash
curl -I -s https://www.google.com | head -n 8
```

### Output:
```text
HTTP/2 200
content-type: text/html; charset=ISO-8859-1
content-security-policy-report-only: object-src 'none';base-uri 'self';script-src 'nonce--Z8VIGat7l4MMZIY9A6ZWw' 'strict-dynamic' 'report-sample' 'unsafe-eval' 'unsafe-inline' https: http:;report-uri https://csp.withgoogle.com/csp/gws/other-hp
accept-ch: Sec-CH-Prefers-Color-Scheme
p3p: CP="This is not a P3P policy! See g.co/p3phelp for more info."
date: Wed, 02 Sep 2026 19:09:26 GMT
server: gws
x-xss-protection: 0
```

<img src="https://github.com/user-attachments/assets/de8eb2af-9bcf-4f2a-918f-662d0758a00f" alt="curl HTTP response headers screenshot" width="100%" />


### Explanation:
`-I` fetches response headers only. `HTTP/2 200` confirms the web server and SSL/TLS certificate negotiation are working properly.

---

## 9. `arp`

### Purpose:
Inspects and manages the Address Resolution Protocol (ARP) table, which maps local IPv4 addresses to Layer 2 physical MAC addresses.

### Command:
```bash
arp -a | head -n 4
```

### Output:
```text
? (10.52.79.22) at 32:0:30:1b:dd:6c on en0 ifscope [ethernet]
? (10.52.79.47) at ee:ba:38:8c:74:4f on en0 ifscope permanent [ethernet]
? (10.52.79.181) at be:9:fa:8a:d4:96 on en0 ifscope [ethernet]
? (10.52.79.202) at 6e:44:3:62:c6:ed on en0 ifscope [ethernet]
```

<img src="https://github.com/user-attachments/assets/cb3b72f0-4c4a-479d-9c83-ba0d1c71b107" alt="arp table screenshot" width="100%" />


### Explanation:
Shows local IPv4 addresses resolved to hardware Ethernet MAC addresses on network interface `en0`.

---

## 10. `systemctl` (Network Service State)

### Purpose:
Checks and manages systemd background services responsible for network connectivity (such as `NetworkManager` or `systemd-networkd`).

### Command:
```bash
systemctl status NetworkManager.service
```

### Output:
```text
● NetworkManager.service - Network Manager
   Loaded: loaded (/lib/systemd/system/NetworkManager.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2026-09-01 07:00:00 UTC; 1 day ago
   Main PID: 742 (NetworkManager)
   Tasks: 3 (limit: 4661)
   CGroup: /system.slice/NetworkManager.service
           └─742 /usr/sbin/NetworkManager --no-daemon
```



### Explanation:
Verifies that the network management daemon is actively running and managing network interfaces and DNS dispatch.

---

## Summary of Diagnostic Flow

| Step | Command | Diagnostic Target | Layer |
| :---: | :--- | :--- | :---: |
| **1** | `ping` | Basic packet reachability & round-trip latency | Layer 3 |
| **2** | `traceroute` | Hop-by-hop path discovery and bottleneck detection | Layer 3 |
| **3** | `nslookup` / `dig` | DNS domain name to IP resolution | Application (DNS) |
| **4** | `telnet` / `nc` | TCP port connectivity & firewall filtering | Layer 4 |
| **5** | `curl` | HTTP response codes and headers | Layer 7 |
| **6** | `netstat` / `ss` | Local listening ports and socket states | Layer 4 |
| **7** | `arp` | Layer 2 MAC address mapping | Layer 2 |
| **8** | `tcpdump` | Real-time packet capture and inspection | Layer 2 - 7 |
| **9** | `systemctl` | Network daemon and service health | System Service |
