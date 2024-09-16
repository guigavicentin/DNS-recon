
#!/bin/bash

# Solicitar o domínio ao usuário
read -p "Digite o domínio a ser consultado: " DOMAIN

# Solicitar o diretório para salvar os resultados
read -p "Digite o diretório onde os resultados serão salvos: " OUTPUT_DIR

# Criar o diretório se não existir
mkdir -p $OUTPUT_DIR

# Arquivos de saída
VALID_SUBDOMAINS_FILE="$OUTPUT_DIR/valid_subdomains.txt"
DIG_OUTPUT_FILE="$OUTPUT_DIR/dig_results.txt"
HOST_OUTPUT_FILE="$OUTPUT_DIR/host_results.txt"
NSLOOKUP_OUTPUT_FILE="$OUTPUT_DIR/nslookup_results.txt"

# Limpar arquivos de saída
> $DIG_OUTPUT_FILE
> $HOST_OUTPUT_FILE
> $NSLOOKUP_OUTPUT_FILE
> $VALID_SUBDOMAINS_FILE

# Função para validar e salvar subdomínios com IPs válidos
function validate_and_save {
    local SUBDOMAIN=$1
    IP=$(dig +short A $SUBDOMAIN | head -n 1)
    if [ -n "$IP" ]; then
        echo "$SUBDOMAIN" >> $VALID_SUBDOMAINS_FILE
    fi
}

# Coletar e validar subdomínios usando amass
echo "Executando amass para coletar subdomínios..."
for SUBDOMAIN in $(amass enum -d $DOMAIN); do
    validate_and_save $SUBDOMAIN
done

# Coletar e validar subdomínios usando subfinder
echo "Executando subfinder para coletar subdomínios..."
for SUBDOMAIN in $(subfinder -d $DOMAIN); do
    validate_and_save $SUBDOMAIN
done

# Função para exibir e salvar resultados
function display_and_save {
    echo -e "\n$1" | tee -a $2
}

# Função para realizar consultas DNS
function perform_dns_queries {
    local SUBDOMAIN=$1

    # Consultas usando dig
    display_and_save "=== Resultados usando dig para $SUBDOMAIN ===" $DIG_OUTPUT_FILE
    echo "Consulta A:" >> $DIG_OUTPUT_FILE
    dig A $SUBDOMAIN >> $DIG_OUTPUT_FILE
    echo -e "\nConsulta AAAA:" >> $DIG_OUTPUT_FILE
    dig AAAA $SUBDOMAIN >> $DIG_OUTPUT_FILE
    echo -e "\nConsulta MX:" >> $DIG_OUTPUT_FILE
    dig MX $SUBDOMAIN >> $DIG_OUTPUT_FILE
    echo -e "\nConsulta NS:" >> $DIG_OUTPUT_FILE
    dig NS $SUBDOMAIN >> $DIG_OUTPUT_FILE
    echo -e "\nConsulta TXT:" >> $DIG_OUTPUT_FILE
    dig TXT $SUBDOMAIN >> $DIG_OUTPUT_FILE
    echo -e "\nConsulta CNAME:" >> $DIG_OUTPUT_FILE
    dig CNAME $SUBDOMAIN >> $DIG_OUTPUT_FILE
    echo -e "\nConsulta SOA:" >> $DIG_OUTPUT_FILE
    dig SOA $SUBDOMAIN >> $DIG_OUTPUT_FILE
    echo -e "\nConsulta PTR (reverso):" >> $DIG_OUTPUT_FILE
    dig -x $(dig +short A $SUBDOMAIN) >> $DIG_OUTPUT_FILE
    echo -e "\nConsulta HINFO:" >> $DIG_OUTPUT_FILE
    dig HINFO $SUBDOMAIN >> $DIG_OUTPUT_FILE

    # Consultas usando host
    display_and_save "=== Resultados usando host para $SUBDOMAIN ===" $HOST_OUTPUT_FILE
    echo "Consulta A:" >> $HOST_OUTPUT_FILE
    host $SUBDOMAIN >> $HOST_OUTPUT_FILE
    echo -e "\nConsulta MX:" >> $HOST_OUTPUT_FILE
    host -t MX $SUBDOMAIN >> $HOST_OUTPUT_FILE
    echo -e "\nConsulta NS:" >> $HOST_OUTPUT_FILE
    host -t NS $SUBDOMAIN >> $HOST_OUTPUT_FILE
    echo -e "\nConsulta TXT:" >> $HOST_OUTPUT_FILE
    host -t TXT $SUBDOMAIN >> $HOST_OUTPUT_FILE
    echo -e "\nConsulta CNAME:" >> $HOST_OUTPUT_FILE
    host -t CNAME $SUBDOMAIN >> $HOST_OUTPUT_FILE
    echo -e "\nConsulta HINFO:" >> $HOST_OUTPUT_FILE
    host -t HINFO $SUBDOMAIN >> $HOST_OUTPUT_FILE

    # Consultas usando nslookup
    display_and_save "=== Resultados usando nslookup para $SUBDOMAIN ===" $NSLOOKUP_OUTPUT_FILE
    echo "Consulta A:" >> $NSLOOKUP_OUTPUT_FILE
    nslookup $SUBDOMAIN >> $NSLOOKUP_OUTPUT_FILE
    echo -e "\nConsulta MX:" >> $NSLOOKUP_OUTPUT_FILE
    nslookup -query=MX $SUBDOMAIN >> $NSLOOKUP_OUTPUT_FILE
    echo -e "\nConsulta NS:" >> $NSLOOKUP_OUTPUT_FILE
    nslookup -query=NS $SUBDOMAIN >> $NSLOOKUP_OUTPUT_FILE
    echo -e "\nConsulta TXT:" >> $NSLOOKUP_OUTPUT_FILE
    nslookup -query=TXT $SUBDOMAIN >> $NSLOOKUP_OUTPUT_FILE
    echo -e "\nConsulta CNAME:" >> $NSLOOKUP_OUTPUT_FILE
    nslookup -query=CNAME $SUBDOMAIN >> $NSLOOKUP_OUTPUT_FILE
}

# Realizar consultas para cada subdomínio válido
for SUBDOMAIN in $(cat $VALID_SUBDOMAINS_FILE); do
    perform_dns_queries $SUBDOMAIN
done

# Exibir resultados finais
echo -e "\nResultados salvos em $OUTPUT_DIR"
