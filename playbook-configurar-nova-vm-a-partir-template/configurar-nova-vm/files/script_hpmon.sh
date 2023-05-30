#!/bin/bash

############################################################################################
#   Script de instalacao e configuracao do agente de monitoramento no ambiente YDUQS       #
#          Desenvolvido por Robson Berthelsen - 04/05/2022                                 #
#          robson.berthelsen.ext@ciriontechnologies.com                                    #
#                         Versao: 1.0.0                                                    #
#                                                                                          #
# INSTRUCOES: Coloque esse script no local onde o agente do hpmon                          #
#             foi extraido. Mude a permissao do script: script_hpmon.sh                    #
#             para +x (chmod +x script_hpmon.sh) e execute o script com                    #
#             sh /local_onde_esta_o_script/script_hpmon.sh                                 #
############################################################################################

DIR_ISO=/home/ansible
DIR_MOUNT=/mnt

#Montar a ISO
mount -o loop $DIR_ISO/OA_12.20_Linux.iso $DIR_MOUNT

#Remove instalador
sh $DIR_MOUNT/oainstall.sh -r -a

#Remover arquivos
rm -rf /var/opt/OV/*

## Desativa firewall
echo "Desativando firewall local..."
service firewalld stop
systemctl disable firewalld
echo "Concluido!"

## Adiciona servidores no arquivo /etc/hosts ##
ETC_HOSTS=/etc/hosts

echo "Fazendo backup do arquivo /etc/hosts em /etc/hosts.bkp"
yes | cp $ETC_HOSTS $ETC_HOSTS.bkp
echo "Concluido!"

declare -a HOST=("cta-ger-hpom-01.level3dc.br" "cta-ger-hpom-02.level3dc.br" "hpom-01.level3dc.br" "hpom-02.level3dc.ar" "ats-sv-hpom-03.level3dc.ar" "ats-sv-hpom-04.level3dc.ar")
declare -a HOSTIPS=("189.125.185.233" "189.125.185.234" "189.125.185.164" "189.125.185.165" "189.125.185.166" "189.125.185.167")
declare -a HOSTFQDN=("cta-ger-hpom-01" "cta-ger-hpom-02" "hpom-01" "hpom-02" "ats-sv-hpom-03" "ats-sv-hpom-04")

HOST_LENGHT=${#HOST[@]}

for (( i=0; i<${HOST_LENGHT}; i++ ));
do
        HOST_LINE="${HOSTIPS[i]} \t ${HOST[i]} \t ${HOSTFQDN[i]}"
        if [ -n "$(grep ${HOSTIPS[i]} $ETC_HOSTS)" ]
        then
                echo "${HOSTIPS[i]} ja existe : $(grep ${HOSTIPS[i]} $ETC_HOSTS)"
        else
                echo "Adicionando ${HOST[i]} no arquivo $ETC_HOSTS";
                echo -e $HOST_LINE >> $ETC_HOSTS;

                if [ -n "$(grep ${HOSTIPS[i]} $ETC_HOSTS)" ]
                        then
                        echo "${HOST[i]} foi adicionado com sucesso!";
                else
                        echo "Falha ao adicionar o host ${HOSTIPS[i]}. Tente novamente!"
                        exit 1
                fi
        fi
done

## Verifica rota ##
#echo "Verificando se existe rota 189.125.185.0...."
#EXIST=$(route -n|grep 189.125.185.0 | wc -l)
#if [ $EXIST -eq 0 ]
#then
#    echo "Validando se é ambinete de PRD ou DR...:"
#    echo ""
#    IPPRD=$(ip a| grep 10.230 | wc -l)
#    IPDR=$(ip a | grep 10.220 | wc -l)
#    if [ $IPPRD -eq 1 ]
#    then
#        INTERFACEPRD=$(route -n | grep 10.230 | awk '{ print $8 }' | tail -n 1)
#        INTERFACEFINAL=$INTERFACEPRD
#        echo "Adicionando rota a interface $INTERFACEPRD do ambiente de producao..."
#        route add -net 189.125.185.0 netmask 255.255.255.0 gw 10.230.132.1 dev $INTERFACEPRD
#        route add -net 189.125.183.0 netmask 255.255.255.0 gw 10.230.132.1 dev $INTERFACEPRD
#    elif [ $IPDR -eq 1 ]
#    then
#        INTERFACEDR=$(route -n | grep 10.220 | awk '{ print $8 }' | tail -n 1)
#        INTERFACEFINAL=$INTERFACEDR
#        echo "Adicionando rota a interface $INTERFACEDR do ambiente de DR..."
#        route add -net 189.125.185.0 netmask 255.255.255.0 gw 10.220.132.1 dev $INTERFACEDR
#        route add -net 189.125.183.0 netmask 255.255.255.0 gw 10.220.132.1 dev $INTERFACEDR
#    fi
#    route -n
#    echo "Concluido!"
#fi
#if [ $EXIST -eq 1 ]
#then
#	echo "Validando se é ambinete de PRD ou DR...:"
#    echo ""
#    IPPRD=$(ip a| grep 10.230 | wc -l)
#    IPDR=$(ip a | grep 10.220 | wc -l)
#    if [ $IPPRD -eq 1 ]
#    then
#        INTERFACEPRD=$(route -n | grep 10.230 | awk '{ print $8 }' | tail -n 1)
#        INTERFACEFINAL=$INTERFACEPRD
#    elif [ $IPDR -eq 1 ]
#    then
#        INTERFACEDR=$(route -n | grep 10.220 | awk '{ print $8 }' | tail -n 1)
#		INTERFACEFINAL=$INTERFACEDR
#    fi
#    route -n
#    echo "Rota para 189.125.185.0 já existe..."
#fi

## Testa conectividade com os servidores ##
HOST_LENGHT=3
WAITFOR=5
TIMES=3

for (( i=0; i<${HOST_LENGHT}; i++ ));
do
   echo "Testando conectividade com o servidor ${HOST[i]}...."
   ping ${HOST[i]} -c $TIMES -i $WAITFOR &> /dev/null
   pingReturn=$?

   if [ $pingReturn -eq 0 ]
   then
       echo "Sucesso!!!"
   else
       echo "Falhou a comunicacao com o host: ${HOST[i]}"
       exit 1
   fi
done

##Falta verificar conexão com porta 383

## Instala dependencias ##
echo "Instalando dependencias..."
yum install m4 libnsl ncurses-libs ncurses ncurses-devel.x86_64 ncurses-compat-libs -y
echo "Concluido!"


## Instala o agente ##
echo "Instalando agente do hpom..."
chmod +x $DIR_MOUNT/oainstall.sh
sh $DIR_MOUNT/oainstall.sh -i -a -minprecheck -cs cta-ger-hpom-01 -s cta-ger-hpom-01 -includeupdates

## Configura o agente ##
echo "Configurando o agente...."
/opt/OV/bin/ovconfchg -ns eaagt -set OPC_INT_MSG_FLT TRUE
/opt/OV/bin/oalicense -set -type PERMANENT "Glance Software LTU"
/opt/OV/bin/oalicense -set -type PERMANENT "HP Operations OS Inst Adv SW LTU"
/opt/OV/bin/oalicense -set -type PERMANENT "HP Ops OS Inst to Realtime Inst LTU"
/opt/OV/bin/ovconfchg -ns sec.core.auth -set MANAGER cta-ger-hpom-01.level3dc.br
/opt/OV/bin/ovconfchg -ns sec.core.auth -set MANAGER_ID c0a22bf8-bad5-7564-1ced-aed49f6a2bed
/opt/OV/bin/ovconfchg -ns sec.cm.client -set CERTIFICATE_SERVER cta-ger-hpom-01.level3dc.br
/opt/OV/bin/ovconfchg -ns sec.core.ssl -set COMM_PROTOCOL TLSv1.2
/opt/OV/bin/ovconfchg -ns sec.core -set HASH_ALGO eSHA512
echo "Concluido!"

## Reinicia o agente ##
#echo "Reiniciando o agente..."
#/opt/OV/bin/ovc -restart
#/opt/OV/bin/opcagt -restart
#echo "Concluido!"

## Verifica status do agente ##
#echo "Verificando status do agente..."
#/opt/OV/bin/ovc
#/opt/OV/bin/opcagt
#echo "Concluido!"

## Gera certificado ##
echo "Gerando certificado..."
/opt/OV/bin/ovcert -certreq
/opt/OV/bin/ovcert -list
echo "Concluido!"

## Garante que o envio do certificado esteja OK ##
echo "Garantindo envio do certificado"
/opt/OV/bin/OpC/install/opcactivate -srv cta-ger-hpom-01
echo "Concluido!"

#HOSTNAME=$(hostname)
#HOSTNAMEIP=$(ip -4 addr show $INTERFACEFINAL | grep -oP "(?<=inet ).*(?=/)")
#echo "Configuracao e instalacao do agente finalizados."
#echo "Informe Rodrigo sobre a inclusao do host $HOSTNAME com IP $HOSTNAMEIP no monitoramento."


#Configuracao final
#echo "Atencao, finalize a configuracao do agente" 
#ovconfchg -edit

#[bbc.http]
#CLIENT_BIND_ADDR=10.230.133.89

## Remove rota ##
#echo "Verificando se existe rota 189.125.185.0...."
#EXIST=$(route -n|grep 189.125.185.0 | wc -l)
#if [ $EXIST -eq 0 ]
#then
#    echo "Validando se é ambinete de PRD ou DR...:"
#    echo ""
#    IPPRD=$(ip a| grep 10.230 | wc -l)
#    IPDR=$(ip a | grep 10.220 | wc -l)
#    if [ $IPPRD -eq 1 ]
#    then
#        INTERFACEPRD=$(route -n | grep 10.230 | awk '{ print $8 }' | tail -n 1)
#        INTERFACEFINAL=$INTERFACEPRD
#        echo "Removendo rota a interface $INTERFACEPRD do ambiente de producao..."
#        route del -net 189.125.185.0 netmask 255.255.255.0 gw 10.230.132.1 dev $INTERFACEPRD
#        route del -net 189.125.183.0 netmask 255.255.255.0 gw 10.230.132.1 dev $INTERFACEPRD
#    elif [ $IPDR -eq 1 ]
#    then
#        INTERFACEDR=$(route -n | grep 10.220 | awk '{ print $8 }' | tail -n 1)
#        INTERFACEFINAL=$INTERFACEDR
#        echo "Removendo rota a interface $INTERFACEDR do ambiente de DR..."
#        route del -net 189.125.185.0 netmask 255.255.255.0 gw 10.220.132.1 dev $INTERFACEDR
#        route del -net 189.125.183.0 netmask 255.255.255.0 gw 10.220.132.1 dev $INTERFACEDR
#    fi
#    route -n
#    echo "Concluido!"
#fi


#Finaliza a instalacao
umount -fl $DIR_MOUNT
rm -rf $DIR_ISO/OA_12.20_Linux.iso
rm -rf $DIR_ISO/script_hpmon.sh
