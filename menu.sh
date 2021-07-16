#! /bin/bash

Check(){
if [[ -a $1 ]]; then
    Result='1'
else
    Result='0'
fi
}

Check bin
if [[ $Result = 0 ]];then
    echo "./Bin not found,Download!"
    wget https://hub.fastgit.org/wwrrj/AIUT/releases/download/v1-beta/binary.zip > /dev/null 2>&1
    unzip -d ./bin binary.zip
    Check binary.zip
    if [[ $Result = 1 ]];then
        rm -rf binary.zip
    fi
    clear
    echo "Done!!!"
fi

Menu(){
    echo "----------------------------------"
    echo "The last run result: " 
    cat ./bin/.create
    echo "----------------------------------"
    echo "一.分解专区"
    echo "  1.system.new.dat.br --> system.new.dat"
    echo "  2.system.new.dat --> system.img"
    echo "  3.vendor.new.dat.br --> vendor.new.dat"
    echo "  4.vendor.new.dat --> vendor.img"
    echo "  5.分解system.img"
    echo "  6.分解vendor.img"
    echo "  7.分解boot/recovery.img"
    echo "----------------------------------"
}

Usage(){
    echo "Usage: bash $0 <Tool Options> [--m] [ --c]"
    echo -e "\tTool Options: You can enter $0 --m to view Tool Options"
    echo -e "\t--m: Show options"
    echo -e "\t--u: Unpack Android Images"
    echo -e "\t--c: Clean up tool path"
}

Clean(){
    rm -rf Input/*
    echo "Done!Back to main menu!" > ./bin/.create
}

UnpackBr(){
    Check Input/$1.new.dat
    if [[ $Result = 0 ]];then
        ./bin/brotli -d Input/$1.new.dat.br
        Check Input/system.new.dat
        if [[ $Result = 1 ]];then
            echo "Done!!!!!!!" > ./bin/.create
         else
            echo "Fuck!!!Where's my $1.new.dat?!!" > ./bin/.create
        fi
    else
        rm -rf Input/$1.new.dat
        UnpackBr $1
    fi
}

UnpackDat(){
    Check Input/$1.img
    if [[ $Result = 0 ]];then
        Check Input/$1.transfer.list
        if [[ $Result = 1 ]];then
            python ./bin/sdat2img.py ./Input/$1.transfer.list ./Input/$1.new.dat ./Input/$1.img | grep Done
            Check Input/system.img
            if [[ $Result = 1 ]];then
                echo "Done!!!!!!!" > ./bin/.create
            else
                echo "Fuck!!!Where's my $1.img?!!" > ./bin/.create
            fi
        else
            echo "Fuck!!!Where's my $1.transfer.list?!!" > ./bin/.create
        fi
    else
        rm -rf Input/$1.img
        UnpackDat $1
    fi
}

UnpackIMG(){
    Check Input/$1
    if [[ $Result = 0 ]];then
        python3 ./bin/imgextractor.py ./Input/$1.img ./Input/
        Check Input/$1
        if [[ $Result = 1 ]];then
            echo "Done!!!!!!!" > ./bin/.create
        else
            echo "Fuck!!!Where's my $1?!!" > ./bin/.create
        fi
    else
        rm -rf Input/$1
    fi
}

Check './bin/.create' 
if [[ $Result = "0" ]];then
    mkdir Input
    touch ./bin/.create
fi


if [[ $1 = "--m" ]]; then 
    Menu
    read -p "Choose: " Choose
elif [[ $1 = "--c" ]]; then
    read -p "Are you sure you want to clean up work path?[y(es)/n(o)]" yn
    if [[ $yn == y ]];then
        Clean
        Menu
    elif [[ $yn == yes ]];then
        Clean
        Menu
    elif [[ $yn == n ]];then
        echo "OK, return to the menu" > ./bin/.create
        Menu
    elif [[ $yn == no ]];then
        echo "OK, return to the menu" > ./bin/.create
        Menu
    fi
else
    Usage
fi


if [[ $Choose = "1" ]];then
    Check Input/system.new.dat.br
    if [[ $Result = 1 ]];then
        UnpackBr system
        Menu
    else
        echo "Input/system.new.dat.br not found!!!!!!" > ./bin/.create
        Menu        
    fi
elif [[ $Choose = "2" ]];then
    Check Input/system.new.dat
    if [[ $Result = 1 ]];then
        UnpackDat system
        Menu
    else
        echo "Input/system.new.dat not found!!!!!!" > ./bin/.create
        Menu
    fi
elif [[ $Choose = "3" ]];then
    Check Input/vendor.new.dat.br
    if [[ $Result = 1 ]];then
        UnpackBr vendor
        Menu
    else
        echo "Input/vendor.new.dat.br not found!!!!!!" > ./bin/.create
        Menu
    fi
elif [[ $Choose = "4" ]];then
    Check Input/vendor.new.dat
    if [[ $Result = 1 ]];then
        UnpackBr vendor
        Menu
    else
        echo "Input/vendor.new.dat not found!!!!!!" > ./bin/.create
        Menu
    fi
elif [[ $Choose = "5" ]];then
    Check Input/system.img
    if [[ $Result = 1 ]];then
        UnpackIMG system
        Menu
    else
        echo "Input/system.img found!!!!!!" > ./bin/.create
        Menu
    fi
elif [[ $Choose = "6" ]];then
    Check Input/vendor.img
    if [[ $Result = 1 ]];then
        UnpackIMG vendor
        Menu
    else
        echo "Input/vendor.img not found!!!!!!" > ./bin/.create
        Menu
    fi    
fi