#!/bin/zsh

#qsreplace - https://github.com/tomnomnom/qsreplace
#KXSS - https://github.com/tomnomnom/hacks/tree/master/kxss
#Assetfinder - https://github.com/tomnomnom/assetfinder
#Subfinder - https://github.com/projectdiscovery/subfinder
#Amass - https://github.com/OWASP/Amass
#Sublist3r - https://github.com/aboul3la/Sublist3r
#Httprobe - https://github.com/tomnomnom/httprobe
#Subzy - https://github.com/LukaSikic/subzy
#Nuclei - https://github.com/projectdiscovery/nuclei/
#Titlextractor - https://github.com/dellalibera/titlextractor/
#Toslack - https://github.com/jthack/toslack
#Notify - https://github.com/projectdiscovery/notify
#Crlfuzz  - https://github.com/dwisiswant0/crlfuzz





#TARGET=$1
#DIR=$2

[ -z "$1" ] && { printf "\n [+]Please Use recon example.com tmm balsh bedan[+]\n";exit;}

#------------------------------------------------#
echo -e "Start Assetfinder\n"
#------------------------------------------------#
assetfinder --subs-only $1 |tee assetfinder.txt
#------------------------------------------------#
echo -e "Start Amass \n"
#------------------------------------------------#
amass enum -d $1 -o amass.txt
#------------------------------------------------#
echo -e "Start Subfinder \n"
#------------------------------------------------#
subfinder -d $1 -o subfinder.txt
#------------------------------------------------#
echo -e "Start Sublist3r \n"
#------------------------------------------------#
sublist3r -d $1 |tee sublist3r.txt
#------------------------------------------------#
echo -e "Start Sort \n"
#------------------------------------------------#
cat sublist3r.txt subfinder.txt amass.txt assetfinder.txt|sort -u|tee Final-subs.txt
#------------------------------------------------#
echo -e "Start Subzy \n"
#------------------------------------------------#
subzy -targets -timeout 5 -hide_fails -concurrency 40 |tee $1-subzy.txt
#------------------------------------------------#
echo -e "Start Httpx \n"
#------------------------------------------------#
cat Final-subs.txt|httpx -threads 100 -timeout 4 -o $1-alive-subs.txt
#------------------------------------------------#
echo -e "Start Titleextractor \n"
#------------------------------------------------#
cat $1-alive-subs.txt|titlextractor -f -c|tee $1-subs-title.txt
#------------------------------------------------#
echo -e "[+]Finish All Subdomain Enum for $1 target *$(wc -l "Final-subs.txt")* for None-Alive Subdomains and *$(wc -l "$1-alive-subs.txt")* for alive subdomains  "|notify -discord -discord-webhook-url "https://discord.com/api/webhooks/806494192409903134/ac9LWdRIHGDYFdoWeha_c66KHjipQrb1o7nz-du7aHXBwLx3EBx2aFZLCinhz3LWzjuy"
#------------------------------------------------#
echo -e "[+] Start CRLFUZZ [+]"
#------------------------------------------------#
crlfuzz -l $1-alive-subs.txt -s |tee crlfuzz.txt
#------------------------------------------------#
echo -e "[+] Finish CRLFUZZ And Found *$(wc -l < crlfuzz.txt)*"
#------------------------------------------------#
mkdir nuclei
#------------------------------------------------#
echo -e "[+] Start Nuclei [+]"
#------------------------------------------------#

nuclei -l $1-alive-subs.txt -t "/root/nuclei-templates/cves/*/*.yaml" -o nuclei/cves.txt -silent -c 60
nuclei -l $1-alive-subs.txt -t "/root/nuclei-templates/exposed-panels/" -o nuclei/exposed-panels.txt -silent
nuclei -l $1-alive-subs.txt -t "/root/nuclei-templates/exposed-tokens/*/*.yaml" -o nuclei/exposed-tokens.txt -c 60 -silent
nuclei -l $1-alive-subs.txt -t "/root/nuclei-templates/exposures/*/*.yaml" -o nuclei/exposures.txt -c 60 -silent
nuclei -l $1-alive-subs.txt -t "/root/nuclei-templates/vulnerabilities/*/*.yaml" -o nuclei/vulnerabilitiess.txt -c 60 -silent
nuclei -l $1-alive-subs.txt -t "/root/nuclei-templates/misconfiguration/*/*.yaml" -o nuclei/misconfiguration.txt -c 60 -silent

#------------------------------------------------#
echo -e "[+] Nuclei List Directory *$(ls "./nuclei/")* "|notify -discord -discord-webhook-url "https://discord.com/api/webhooks/806494192409903134/ac9LWdRIHGDYFdoWeha_c66KHjipQrb1o7nz-du7aHXBwLx3EBx2aFZLCinhz3LWzjuy"
#------------------------------------------------#
echo -e "[+] Start Waybackurls with KXSS [+]"
#------------------------------------------------#
cat $1-alive-subs.txt| waybackurls | grep "https://" | grep -v "png\|jpg\|css\|js\|gif\|txt\|pdf" | grep "=" | qsreplace | qsreplace -a|kxss|tee kxss.txt
#------------------------------------------------#
