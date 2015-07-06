cmnd=$1
client=$(echo $2 | tr 'a-z' 'A-Z')
slice_tenant_name=$3
location=$4
vm_type=$5
size=$6
public_key_name=$7
vm_name=$8

mkdir -p images
mkdir -p logs
mkdir -p tmp

#logs file allocation
path=$(pwd)
slice_creation="$path/logs/slice_create.log"
slice_deletion="$path/logs/slice_delete.log"
vm_geni_creation="$path/logs/vm_create_geni.log"
vm_savi_creation="$path/logs/vm_create_savi.log"
vm_savi_deletion="$path/logs/vm_delete_savi.log"
vm_geni_deletion="$path/logs/vm_delete_geni.log"
images_list="$path/images/images_list.log"
key_name="~/.ssh/$public_key_name"
key_validation="$path/logs/adding_key_pair.log"

main()
    {
        if [ -e "savi_config" ]; then
            echo "Configuring environment variables. Please Wait.. "
            source savi_config
        else    
            echo -n "Please Enter your USERID: "
                read id
            echo -n "Please Enter your PASSWORD: "
                read pass
            echo -n "Please Enter your Project-ID/Tenant Name: "
                 read tenant
            echo "export OS_USERNAME=$id" >> savi_config
            echo "export OS_PASSWORD=$pass" >> savi_config
            echo "export OS_REGION_NAME=EDGE-TR-1" >> savi_config
            echo "export OS_TENANT_NAME=$tenant" >> savi_config
            echo "export OS_AUTH_URL=http://iam.savitestbed.ca:5000/v2.0/" >> savi_config
            echo "Configuring environment variables. Please Wait.. "
            source savi_config
            nova list 2>> credentialcheck.log
            credential_check=$(grep "ERROR" credentialcheck.log)
                if [ -z "$credential_check" ]; then
                   echo "Environment variables required for Savi Server set Successfully"
                else
                   rm savi_config
                   rm credentialcheck.log
                   #clear
                   echo "INVALID Credentials provided. Please run the script again"
                   exit
                fi
        fi
        

        case $cmnd in 
            #crete a new vm at different clients/servers
            createvm)
                if [ "$client" = "SAVI" ]; then
                    if [ -z "$vm_name" ]; then
                        echo "Not all the arguments are provided"
                    else   
                        #clear
                        echo "Creating VM on Savi Instance.."
                        create_vm
                    fi   
                elif [ "$client" = "GENI" ]; then
                    if [ -z "$vm_type" ]; then
                        echo "Not all the arguments are provided"
                    else   
                        echo "Creating VM on Geni Instance.."
                        create_vm
                    fi   
                elif [ -z "$client" ]; then
                    echo "No client Name Provided"
                else
                    echo "Invalid Arguments"       
                fi   
            ;;
            createslice)   
                #clear
                if [ "$client" = "SAVI" ]; then
                    echo "This feature is only available for GENI"
                elif [ "$client" = "GENI" ]; then
                    echo "Gathering Information..."
                    create_slice
                elif [ -z "$client" ]; then
                    echo "Invalid Client Name."
                else   
                    echo "Invalid Arguments"       
                fi   
            ;;   
            deleteslice)
                #clear
                if [ "$client" = "SAVI" ]; then
                    echo "This feature is only available for GENI"
                elif [ "$client" = "GENI" ]; then
                    echo "Gathering Information..."
                    delete_slice
                elif [ -z "$client" ]; then
                    echo "Invalid Client Name."
                else
                    echo "Invalid Argument"       
                fi   
            ;;   
            deletevm)
                #clear
                if [ "$client" = "SAVI" ]; then
                    if [ -z "$vm_type" ]; then
                        echo "Not all the arguments are provided"
                    else   
                        echo "Deleting instance from Savi"
                        delete_vm
                    fi   
                elif [ "$client" = "GENI" ]; then
                    if [ -z "$slice_tenant_name" ]; then
                        echo "Not all the arguments are provided"
                    else   
                        delete_vm
                    fi   
                elif [ -z "$client" ]; then
                    echo "No client Name Provided"
                else
                    echo "Invalid Arguments"       
                fi   
            ;;   
            listinstance)
                #clear
                if [ -z "$slice_tenant_name" ]; then
                    echo "Not all arguments are provided"
                else    
                list_instance
                fi
            ;;   
            generatekey)
                generate_key
            ;;   

            location)
                #clear
                location
            ;; 
            add_public_ip)
                #clear
                add_public_ip
            ;; 
            *)
                echo "Command Not found"
        esac       
    }

#slice actions on Geni Client
create_slice()
    {
        omni.py createslice $slice_tenant_name 2> $slice_creation
        echo -e "\n"
        grep "Result Summary" $slice_creation
        echo -e "\n"
        # grep "ERROR" slice_creation.log
    }



delete_slice()
    {
        if [ -z "$slice_tenant_name" ]; then
                    echo "Slice name not provided"
        else           
            omni.py deleteslice $slice_tenant_name 2> $slice_deletion
            echo -e "\n"
            grep "Result Summary" $slice_deletion
        fi   
    }


create_vm()
    {
         #creating vm for GENI   
        if [ "$client" = "GENI" ]; then
            rspec_file="$path/rspecs/$vm_type.rspec"
             omni.py -a $location createsliver $slice_tenant_name $rspec_file 2> $vm_geni_creation
             echo $vm_geni_creation
            check_failure=$(grep "Failed" $vm_geni_creation)
            echo $check_failure
            if [ -z "$check_failure" ]; then
                echo -e "\n"
                grep "Result Summary" $vm_geni_creation
                hostname=$(grep -o 'hostname="*[^"]*"' $vm_geni_creation | tail -1)
                echo '"'$hostname
                echo -e "\n To connect to the created VM please use to the given $hostname \n"
            else
                echo -e "\n"   
                grep "Result Summary" $vm_geni_creation
                #echo -e "\n Please check the Logs and take appropriate steps\n"
                grep "Result Summary" $vm_geni_creation
                hostname=$(grep -o 'hostname="*[^"]*"' $vm_geni_creation | tail -1)
                echo '"'$hostname
                ./tutorial.sh listinstance geni
            fi   
        #creating vm for SAVI   
         elif [ "$client" = "SAVI" ]; then
             slice_tenant_name=$(echo $slice_tenant_name | tr 'A-Z' 'a-z')
             echo "export OS_TENANT_NAME=$slice_tenant_name" > current_savi_config
             location=$(echo $location | tr 'a-z' 'A-Z')
             #case $location in
             #    CORE)
             #       location="CORE"
             #   ;;
             #   WATERLOO)
             #       location="EDGE-WT-1"
             #   ;;
             #   CARLETON)
             #       location="EDGE-CT-1"
             #   ;;
             #   YORK)
             #       location="EDGE-YK-1"
             #   ;;
             #   TORONTO)
             #       location="EDGE-TR-1"
             #   ;;
             #   MCGILL)
             #       location="EDGE-MG-1"
             #   ;;
             #   CALGARY)
             #       location="EDGE-CG-1"
             #   ;;
             #   VICTORIA)
             #       location="EDGE-VC-1"
             #   ;;   
             #esac
             echo "export OS_REGION_NAME=$location" > current_savi_config
             source current_savi_config
             # vm_type=$(echo $vm_type | tr 'A-Z' 'a-z')
                  echo $vm_type
                  nova image-list | grep $vm_type | cut -s -d '|' -f2 | cut -s -d ' ' -f2 > $images_list
                  no_of_id=$(cat $images_list|wc -l)
                  if [ "$no_of_id" -eq 0 ]; then
                      echo "Image Not available"
                  elif [ "$no_of_id" -gt 1 ]; then
                      echo "Too many matches for image name please provide the exact name"
                  else   
                      image_id=$(cat $images_list)
                      size=$(echo $size | tr 'a-z' 'A-Z')
                    #assigning flavours to the vm
                      case $size in 
                        TINY)
                            flavor_id=1
                        ;;
                        SMALL)
                            flavor_id=2
                        ;;
                        MEDIUM)
                            flavor_id=3
                        ;;
                        LARGE)
                            flavor_id=4
                        ;;
                        XLARGE)
                            flavor_id=5
                        ;;
                        *)
                        "Invalid flavor"
                        echo "Please run the script again with appropriate arguments"
                        exit
                        ;;
                    esac   
                    #adding key pair to the savi edge
                     nova keypair-add --pub_key $key_name.pub $public_key_name 2> $key_validation
                     nova boot --image $image_id --flavor $flavor_id --key_name $public_key_name $vm_name 2>$vm_savi_creation
                     cat $vm_savi_creation
                    
                    sleep 30

                    neutron floatingip-create ext_net >> ip_address_allocation.log
                    ip_address=$(cat ip_address_allocation.log | grep floating_ip_address | cut -s -d '|' -f3)
                    nova list | grep $vm_name | cut -s -d '|' -f2 1>machine_id.log
                    machine_id=$(cat machine_id.log)
                    nova add-floating-ip $machine_id $ip_address
                    today=`date '+%Y_%m_%d__%H_%M_%S'`;
                    rename s/.log/_$today.log/ *.log
                    mv $path/*.log $path/logs/
                fi
                 
         else
             echo "Invalid client name"
         fi               

                       
    }   

delete_vm()
    {
        #for deletion of any vm the 3rd argument is vmname for savi so reassigning the variables in this function
        if [ "$client" = "SAVI" ]; then
            source savi_config
            slice_tenant_name=$(echo $slice_tenant_name | tr 'A-Z' 'a-z')
            export OS_TENANT_NAME=$slice_tenant_name
            # location=$(echo $location | tr 'a-z' 'A-Z')
            # export OS_REGION_NAME=$location
            location=$(echo $location | tr 'a-z' 'A-Z')
            #case $location in
            #    CORE)
            #       location="CORE"
            #   ;;
            #   WASHINGTON)
            #       location="EDGE-WT-1"
            #   ;;
            #   CANATICUT)
            #       location="EDGE-CT-1"
            #   ;;
            #   YORK)
            #       location="EDGE-YK-1"
            #   ;;
            #   TORONTO)
            #       location="EDGE-TR-1"
            #   ;;
            #   MACGILL)
            #       location="EDGE-MG-1"
            #   ;;
            #   CALGARY)
            #       location="EDGE-CG-1"
            #   ;;
            #   VICTORIA)
            #       location="EDGE-VC-1"
            #   ;;   
            #esac
            export OS_REGION_NAME=$location
            vm_name=$vm_type
            nova delete $vm_name 2> $vm_savi_deletion
            if [[ -s $vm_savi_deletion ]]; then
                err_mssg=$(grep "ERROR" $vm_savi_deletion)
                if [ "$err_mssg" = "ERROR: Multiple server matches found for '$vm_name', use an ID to be more specific." ]; then
                    echo -e "$err_mssg. \n\n Please list all instances to get the ID\n"
                else
                     echo -e "\n $err_mssg\n"   
                fi    
            else
                echo "Instance Terminated Successfully" > $vm_savi_deletion
                cat $vm_savi_deletion
            fi
        elif [ "$client" = "GENI" ]; then
            echo "Deleting all the resources in slice:- $slice_tenant_name"
            omni.py deletesliver $slice_tenant_name --useSliceAggregates 2> $vm_geni_deletion
            grep "Result Summary" $vm_geni_deletion


        fi                   

    }

list_instance()
{   
            # source current_savi_config
            if [ "$client" = "SAVI" ]; then
            # if [ -z "$slice_tenant_name" ]; then
            #     current_instance=$(env|grep OS_REGION_NAME|cut -s -d "=" -f2)
            #      case $current_instance in
            #          CORE)
            #             current_instance="CORE"
            #         ;;
            #         EDGE-WT-1)
            #             current_instance="WATERLOO"
            #         ;;
            #         EDGE-CT-1)
            #             current_instance="CARLETON"
            #         ;;
            #         EDGE-YK-1)
            #             current_instance="YORK"
            #         ;;
            #         EDGE-TR-1)
            #             current_instance="TORONTO"
            #         ;;
            #         EDGE-MG-1)
            #             current_instance="MCGILL"
            #         ;;
            #         EDGE-CG-1)
            #             current_instance="CALGARY"
            #         ;;
            #         EDGE-VC-1)
            #             current_instance="VICTORIA"
            #         ;;   
            #      esac
            #     echo "Gathering information for the instance $current_instance"
            # else
            slice_tenant_name=$(echo $slice_tenant_name | tr 'a-z' 'A-Z')
            #case $slice_tenant_name in
            #    CORE)
            #        slice_tenant_name="CORE"
            #    ;;
            #    WATERLOO)
            #        slice_tenant_name="EDGE-WT-1"
            #    ;;
            #    CARLETON)
            #        slice_tenant_name="EDGE-CT-1"
            #    ;;
            #    YORK)
            #        slice_tenant_name="EDGE-YK-1"
            #    ;;
            #    TORONTO)
            #        slice_tenant_name="EDGE-TR-1"
            #    ;;
            #    MCGILL)
            #        slice_tenant_name="EDGE-MG-1"
            #    ;;
            #    CALGARY)
            #        slice_tenant_name="EDGE-CG-1"
            #    ;;
            #    VICTORIA)
            #        slice_tenant_name="EDGE-VC-1"
            #    ;;   
            #esac
            echo "$slice_tenant_name"
            export OS_REGION_NAME="$slice_tenant_name"   
            # fi       
            echo "Gathering Information from Savi Servers..."
            # current_instance=$(env|grep OS_REGION_NAME|cut -s -d "=" -f2)
            # echo $current_instance
            nova list >> nova_list.log
            cut -s -d'|' -f3 nova_list.log >> savi_instance_name.tmp
            cut -s -d'|' -f4 nova_list.log >> savi_instance_status.tmp
            cut -s -d'|' -f7 nova_list.log >> savi_instance_address.tmp
            no_of_lines=$(cat savi_instance_status.tmp|wc -l)
                i=1
                while [ "$i" -le "$no_of_lines" ]; do
                        name=$(sed -n ''$i'p' savi_instance_name.tmp)
                        status=$(sed -n ''$i'p' savi_instance_status.tmp)
                        address=$(sed -n ''$i'p' savi_instance_address.tmp)
                        if [ "$i" -eq 1 ]
                        then
                                name="Instance_Name"
                                status="Current_Status"
                                owner="Owner"
                                address="Address"
                                 awk 'BEGIN {print "================================================================================================================"}' >> listinstance_output.tmp
                                 echo -e "$name $status $owner $address" >>listinstance_output.tmp
                                 awk 'BEGIN {print "================================================================================================================"}' >> listinstance_output.tmp
                        else
                                owner="Savi"
                                echo -e "$name $status $owner $address" >>listinstance_output.tmp
                        fi
                        i=$(($i + 1))
                done
            # if [ "$client" = "SAVI" ]; then
                awk '{printf "%-50s%-20s%-20s%-8s%-8s\n",$1,$2,$3,$4,$5}' listinstance_output.tmp > listinstances.log
                awk 'BEGIN {print "================================================================================================================="}' >> listinstances.log
                  # rm *.tmp
                cat listinstances.log
                today=`date '+%Y_%m_%d__%H_%M_%S'`;
                rename s/.log/_$today.log/ *.log
                mv $path/*.log $path/logs/
                rename s/.tmp/_$today.tmp/ *.tmp
                mv $path/*.tmp $path/tmp/
                exit
            # fi
    fi
    if [ "$client" = "GENI" ]; then
                echo "Gathering Information from Geni Servers..."   
                # omni.py listmyslices --useSliceAggregates 2>geni_slice_list.tmp
                # sed -n '/urn/p' geni_slice_list.tmp | rev | cut -d: -f1 | rev |rev | cut -d+ -f1 | rev > geni_slice_name.tmp
                # rm -f sliver_status.tmp
                # no_slice_name=$(cat geni_slice_name.tmp|wc -l)

                # echo "Total number of Slices Associated with the account: $no_slice_name"
                        # i=1
                     # while [ "$i" -le "$no_slice_name" ]; do
                                # slice_name=$(sed -n ''$i'p' geni_slice_name.tmp)
                                slice_name=$(echo $slice_tenant_name)
                                omni.py sliverstatus $slice_name --useSliceAggregates 2>>sliver_status.tmp
                                omni.py listresources $slice_name --useSliceAggregates 2>>sliver_instance.tmp
                             
				 # i=$(($i + 1))
                    # done    
                                #grep -o 'host name="*[^"]*"' sliver_instance.tmp  >> geni_inst_id.tmp
                                #grep -o 'hostname="*[^"]*"' sliver_instance.tmp  >> geni_instance_address.tmp
                                #grep -o 'port="*[^"]*"' sliver_instance.tmp >> geni_instance_port.tmp 
                                grep -o 'host name="*[^"]*"' sliver_instance.tmp  >> geni_inst_id.tmp
                                no_instance=$(cat geni_inst_id.tmp | wc -l)
                                if [ $no_instance > 1 ]; then
                                    grep -o 'hostname="*[^"]*"' sliver_instance.tmp  >> geni_instance_address_temp.tmp
                                    grep -o 'port="*[^"]*"' sliver_instance.tmp >> geni_instance_port_temp.tmp
                                    no_hostnames=$(grep -o 'hostname="*[^"]*"' sliver_instance.tmp | wc -l)
                                    line_number=$(($no_hostnames/$no_instance))
                                    j=1
                                    i=1
                                    while [ "$i" -le "$no_hostnames" ]; do
                                        sed "$j q;d" geni_instance_address_temp.tmp >> geni_instance_address.tmp
                                        sed "$j q;d" geni_instance_port_temp.tmp >> geni_instance_port.tmp

                                        i=$(($i + 1))
                                        j=$(($j + $line_number))
                                    done
                                else
                                    grep -o 'hostname="*[^"]*"' sliver_instance.tmp  >> geni_instance_address.tmp
                                    grep -o 'port="*[^"]*"' sliver_instance.tmp >> geni_instance_port.tmp
                                fi
                    awk '{gsub("host name=","");print}' geni_inst_id.tmp > geni_instance_id.tmp 
                   grep -B 10 "pg_public_url" sliver_status.tmp > geni_status.tmp
                   if [[ -s geni_status.tmp ]] ; then 
                       sed -n '/geni_status/p' geni_status.tmp | cut -s -d ':' -f2 | cut -s -d '"' -f2 > geni_instance_status.tmp
                      # sed -n '/geni_urn/p' geni_status.tmp | cut -s -d ':' -f4 | cut -s -d '"' -f1 > geni_instance_name.tmp
                       no_geni_instance=$(cat geni_instance_status.tmp|wc -l)
                       echo $no_geni_instance
                       if [ -e "listinstance_output.tmp" ]; then
                           file_exist="YES"
                       else
                           file_exist="NO"
                       fi       
                       i=1
                        owner="Geni"
                        while [ "$i" -le "$no_geni_instance" ]; do
                                if [ "$client" = "GENI" -a "$file_exist" = "NO" ]; then
                                     name="Instance_Name"
                                    status="Current_Status"
                                    owner="Owner"
                                    address="Address"    
                                     awk 'BEGIN {print "=============================================================================================================================================================="}' > listinstance_output.tmp 
                                    echo -e "$name $status $owner $address" >>listinstance_output.tmp
                                     awk 'BEGIN {print "=============================================================================================================================================================="}' >> listinstance_output.tmp 
                                  file_exist="YES"
                                    fi
                                    name=$(sed -n ''$i'p' geni_instance_id.tmp)
                                    status=$(sed -n ''$i'p' geni_instance_status.tmp)
                                    owner="Geni"
                                    address=$(sed -n ''$i'p' geni_instance_address.tmp)
                                    port=$(sed -n ''$i'p' geni_instance_port.tmp) 
				   echo -e "$name $status $owner $address $port" >>listinstance_output.tmp
                            i=$(($i + 1))
                        done
                        # if [ "$client" = "GENI" ]; then
                             awk '{printf "%-60s%-20s%-20s%-8s%-6s\n",$1,$2,$3,$4,$5}' listinstance_output.tmp > listinstances.log
                              awk 'BEGIN {print "=================================================================================================================================================================="}' >> listinstances.log
                              # rm *.tmp
                              cat listinstances.log
                              today=`date '+%Y_%m_%d__%H_%M_%S'`;
                            rename s/.log/_$today.log/ *.log
                            mv $path/*.log $path/logs/
                            rename s/.tmp/_$today.tmp/ *.tmp
                            mv $path/*.tmp $path/tmp/
                              exit
                        #   elif [ -z "$client"]; then
                        #       awk '{printf "%-60s%-20s%-20s%-8s%-6s\n",$1,$2,$3,$4,$5}' listinstance_output.tmp > listinstances.log 
                        #      #cat listinstance_output.tmp > listinstances.log
                        #       awk 'BEGIN {print "=================================================================================================================================================================="}' >> listinstances.log
                        #       # rm *.tmp
                        #       cat listinstances.log
                        #       today=`date '+%Y_%m_%d__%H_%M_%S'`;
                        #     rename s/.log/_$today.log/ *.log
                        #     mv $path/*.log $path/logs/
                        #     rename s/.tmp/_$today.tmp/ *.tmp
                        #     mv $path/*.tmp $path/tmp/   
                        # fi
                       
                    else
                           warning=$(grep "No Aggregates left to operate on." sliver_status.tmp)
                           if [ -z "$warning" ]; then
                               echo "Please see log for errors"
                           else
                               echo "There are no Aggregates associated with your GENI Slice."
                               if [ -z "$client" ]; then
                                   cat listinstance_output.tmp > listinstances.log
                                   awk 'BEGIN {print "========================================================================================================="}' >> listinstances.log
                                   cat listinstances.log
                                   today=`date '+%Y_%m_%d__%H_%M_%S'`;
                                rename s/.log/_$today.log/ *.log
                                mv $path/*.log $path/logs/
                                rename s/.tmp/_$today.tmp/ *.tmp
                                mv $path/*.tmp $path/tmp/   
                               fi   
                           fi       
                   fi
    fi   
   
   
}

generate_key()
{
    cd $path/keys
    ssh-keygen -t rsa
    chmod 777 *
    echo "Generated keys are stored at $path/keys"
}

location()
{
    cat location.txt
}

main
source savi_config

