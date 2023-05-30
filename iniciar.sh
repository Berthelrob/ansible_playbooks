#!/bin/bash

opcao=""

echo ""
echo "--> Script de inicialização de configuracao de maquinas virtuais Linux <--"

while [[ $opcao != "0" ]]; do
    echo "Escolha uma opção:"
    echo "1. Configurar uma nova maquina template"
    echo "2. Configurar uma nova VM (opcao deve ser utilizada quando existe uma maquina template)"
    echo "3. Apenas instalar e configurar ambiente grafico"
    echo "4. Instalar e configurar todo um ambiente novo (inclui a opcao 1 e 2)"
    echo "0. Sair"
    read -p "Opção: " opcao

    case $opcao in
        1)
            echo "Executando iniciar-configuracao-novo-template.sh"
            ./scripts/iniciar-configuracao-novo-template.sh
            ;;
        2)
            echo "Executando iniciar-configuracao-nova-vm.sh"
            ./scripts/iniciar-configuracao-nova-vm.sh
            ;;
        3)
            echo "Executando instalar-apenas-ambiente-grafico.sh"
            ./scripts/instalar-apenas-ambiente-grafico.sh
            ;;
	4)
	    echo "Executando instalacao/configuracao-todo-ambiente"
	    ./scripts/iniciar-configuracao-novo-template.sh
	    ./scripts/iniciar-configuracao-nova-vm.sh
	    ;;
        0)
            echo "Saindo..."
            ;;
        *)
            echo "Opção inválida"
            ;;
    esac

    echo
done

#EOF
