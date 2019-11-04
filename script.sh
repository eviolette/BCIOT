 cp Testing1.go ~/fabric-samples/chaincode/testing_chaincode/

#Intall and Upgrade Chaincode
docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" -e "CORE_PEER_ADDRESS=$PEER"  \
    cli peer chaincode install -n $CHAINCODENAME -v v9 -p $CHAINCODEDIR

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode upgrade -o $ORDERER -C $CHANNEL -n $CHAINCODENAME -v v9 \
    -c '{"Args":[]}' --cafile $CAFILE --tls


######################################################################################
########################### Participant Transactions #################################
######################################################################################
#Create Participant
{\"ParticipantType\":\"TEST\", \"OrgName\":\"TEST1ORG\", \"Email\":\"test1@gmail.com\"}
testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["createParticipant","{\"ParticipantType\":\"TEST\", \"OrgName\":\"TEST3ORG\", \"Email\":\"test3@gmail.com\"}","testOrg3"]}' --cafile $CAFILE --tls

{\"ParticipantType\":\"TEST\", \"OrgName\":\"TEST2ORG\", \"Email\":\"test2@gmail.com\"}
testOrg2

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["createParticipant","{\"ParticipantType\":\"TEST\", \"OrgName\":\"TEST2ORG\", \"Email\":\"test2@gmail.com\"}","testOrg2"]}' --cafile $CAFILE --tls


#Get Participant
testOrg1
testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getParticipant","testOrg1", "testOrg1"]}' --cafile $CAFILE --tls

#Delete Participant
testOrg1
testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["deleteParticipant","testOrg1", "testOrg1"]}' --cafile $CAFILE --tls

######################################################################################
######################### Purchase Order Transactions ################################
######################################################################################
#Create Purchase Order
# {
#   \"PurchaseOrderID\":\"TESTPO0001\",
# 	\"Vendor\":\"TEST\",
# 	\"LineItemNumber\":\"TESTLI0001\",
# 	\"MaterialID\":\"TESTMAT0001\",
# 	\"Quantity\":100
# }
# testOrg2

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["createPurchaseOrder","{\"PurchaseOrderID\":\"TESTPO0001\",\"Vendor\":\"TEST\",\"LineItemNumber\":\"TESTLI0001\",\"MaterialID\":\"TESTMAT0001\",\"Quantity\":100}","testOrg2"]}' --cafile $CAFILE --tls

#    {\"PurchaseOrderID\":\"TESTPO0001\",\"Vendor\":\"TEST\",\"LineItemNumber\":\"TESTLI0001\",\"MaterialID\":\"TESTMAT0001\",\"Quantity\":100}

#Get Material
# TESTMAT0001
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getMaterial","TESTMAT0001","testOrg1"]}' --cafile $CAFILE --tls

#Get Purchase Order
# {
#     \"PurchaseOrderID\":\"TESTPO0001\",
# 	\"Owner\":\"testOrg2\"
# }
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getPurchaseOrder","{\"PurchaseOrderID\":\"TESTPO0001\",\"Owner\":\"testOrg2\"}","testOrg2"]}' --cafile $CAFILE --tls

    # {\"PurchaseOrderID\":\"TESTPO0001\",\"Owner\":\"testOrg2\"}


######################################################################################
######################## Production Order Transactions ###############################
######################################################################################
#Create Production Order GR
# {
#     \"ProductionOrderID\":\"TESTPRODORD0001\",
# 	\"MaterialID\":\"TESTMAT0001\",
# 	\"Quantity\":500,
# 	\"Plant\":\"TESTPLANT\",
# 	\"StorageLocation\":\"TESTSLOC\",
#     \"BatchNumber\":\"TESTBATCH0001\"
# }
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["reportProductionOrderGR","{\"ProductionOrderID\":\"TESTPRODORD0001\",\"MaterialID\":\"TESTMAT0001\",\"Quantity\":500,\"Plant\":\"TESTPLANT\",\"StorageLocation\":\"TESTSLOC\",\"BatchNumber\":\"TESTBATCH0001\"}","testOrg1"]}' --cafile $CAFILE --tls

    # {\"ProductionOrderID\":\"TESTPRODORD0001\",\"MaterialID\":\"TESTMAT0001\",\"Quantity\":500,\"Plant\":\"TESTPLANT\",\"StorageLocation\":\"TESTSLOC\",\"BatchNumber\":\"TESTBATCH0001\"}

#Get Material
# TESTMAT0001
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getMaterial","TESTMAT0001","testOrg1"]}' --cafile $CAFILE --tls

#Get Production Order
# {
#     \"ProductionOrderID\":\"TESTPRODORD0001\",
# 	\"Owner\":\"testOrg1\"
# }
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getProductionOrder","{\"ProductionOrderID\":\"TESTPRODORD0001\",\"Owner\":\"testOrg1\"}","testOrg1"]}' --cafile $CAFILE --tls

    # {\"ProductionOrderID\":\"TESTPRODORD0001\",\"Owner\":\"testOrg1\"}

#Get Batch
# {
#     \"MaterialID\":\"TESTMAT0001\",
# 	\"Owner\":\"testOrg1\",
#     \"BatchNumber\":\"TESTBATCH0001\"
# }
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getBatch","{\"MaterialID\":\"TESTMAT0001\",\"Owner\":\"testOrg1\",\"BatchNumber\":\"TESTBATCH0001\"}","testOrg1"]}' --cafile $CAFILE --tls

    # {\"MaterialID\":\"TESTMAT0001\",\"Owner\":\"testOrg1\",\"BatchNumber\":\"TESTBATCH0001\"}

######################################################################################
########################### Sales Order Transactions #################################
######################################################################################

#Create Sales Order
# {
#     \"SalesOrderID\":\"TESTSO0001\",
# 	\"POReference\":\"TESTPO0001\",
# 	\"LineItemNumber\":\"TESTLI0001\",
# 	\"MaterialID\":\"TESTMAT0001\",
# 	\"Quantity\":100
# }
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["createSalesOrder","{\"SalesOrderID\":\"TESTSO0001\",\"POReference\":\"TESTPO0001\",\"LineItemNumber\":\"TESTLI0001\",\"MaterialID\":\"TESTMAT0001\",\"Quantity\":100}","testOrg1"]}' --cafile $CAFILE --tls

    # {\"SalesOrderID\":\"TESTSO0001\",\"POReference\":\"TESTPO0001\",\"LineItemNumber\":\"TESTLI0001\",\"MaterialID\":\"TESTMAT0001\",\"Quantity\":100}

# Get Material
# TESTMAT0001
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getMaterial","TESTMAT0001","testOrg1"]}' --cafile $CAFILE --tls

#Get Sales Order
# {
# 	\"Owner\":\"testOrg1\",
#     \"SalesOrderID\":\"TESTSO0001\"
# }
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getSalesOrder","{\"Owner\":\"testOrg1\",\"SalesOrderID\":\"TESTSO0001\"}","testOrg1"]}' --cafile $CAFILE --tls

    # {\"Owner\":\"testOrg1\",\"SalesOrderID\":\"TESTSO0001\"}

######################################################################################
############################# Delivery Transactions ##################################
######################################################################################
#Create Delivery
# {
#     \"DeliveryNumber\":\"TESTDEL0001\",
# 	\"MaterialID\":\"TESTMAT0001\",
# 	\"HUID\":\"TESTHU0001\",
# 	\"BatchNumber\":\"TESTBATCH0001\",
# 	\"Quantity\":100, 
#     \"SalesOrderID\":\"TESTSO0001\",
#     \"LineItemNumber\":\"TESTLI0001\"
# }
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["createDelivery","{\"DeliveryNumber\":\"TESTDEL0001\",\"MaterialID\":\"TESTMAT0001\",\"HUID\":\"TESTHU0001\",\"BatchNumber\":\"TESTBATCH0001\",\"Quantity\":100, \"SalesOrderID\":\"TESTSO0001\",\"LineItemNumber\":\"TESTLI0001\"}","testOrg1"]}' --cafile $CAFILE --tls

    # {\"DeliveryNumber\":\"TESTDEL0001\",\"MaterialID\":\"TESTMAT0001\",\"HUID\":\"TESTHU0001\",\"BatchNumber\":\"TESTBATCH0001\",\"Quantity\":100, \"SalesOrderID\":\"TESTSO0001\",\"LineItemNumber\":\"TESTLI0001\"}

#Get Delivery
# {
# 	\"Owner\":\"testOrg1\",
#     \"SalesOrderID\":\"TESTSO0001\",
#     \"DeliveryNumber\":\"TESTDEL0001\"
# }
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getDelivery","{\"Owner\":\"testOrg1\",\"SalesOrderID\":\"TESTSO0001\",\"DeliveryNumber\":\"TESTDEL0001\"}","testOrg1"]}' --cafile $CAFILE --tls

    # {\"Owner\":\"testOrg1\",\"SalesOrderID\":\"TESTSO0001\",\"DeliveryNumber\":\"TESTDEL0001\"}

#Get Sales Order
# {
# 	\"Owner\":\"testOrg1\",
#     \"SalesOrderID\":\"TESTSO0001\"
# }
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getSalesOrder","{\"Owner\":\"testOrg1\",\"SalesOrderID\":\"TESTSO0001\"}","testOrg1"]}' --cafile $CAFILE --tls

    # {\"Owner\":\"testOrg1\",\"SalesOrderID\":\"TESTSO0001\"}

#Get Batch
# {
#     \"MaterialID\":\"TESTMAT0001\",
# 	\"Owner\":\"testOrg1\",
#     \"BatchNumber\":\"TESTBATCH0001\"
# }
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getBatch","{\"MaterialID\":\"TESTMAT0001\",\"Owner\":\"testOrg1\",\"BatchNumber\":\"TESTBATCH0001\"}","testOrg1"]}' --cafile $CAFILE --tls

    # {\"MaterialID\":\"TESTMAT0001\",\"Owner\":\"testOrg1\",\"BatchNumber\":\"TESTBATCH0001\"}

######################################################################################
############################# Shipment Transactions ##################################
######################################################################################
#Create Shipment
# {
#     \"DeliveryNumber\":\"TESTDEL0001\",
# 	\"ShipmentID\":\"TESTSHIP0001\",
#     \"SalesOrderID\":\"TESTSO0001\"
# }
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["createShipment","{\"DeliveryNumber\":\"TESTDEL0001\",\"ShipmentID\":\"TESTSHIP0001\",\"SalesOrderID\":\"TESTSO0001\"}","testOrg1"]}' --cafile $CAFILE --tls

    # {\"DeliveryNumber\":\"TESTDEL0001\",\"ShipmentID\":\"TESTSHIP0001\",\"SalesOrderID\":\"TESTSO0001\"}

#Get Shipment
# TESTSHIP0001
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getShipment","TESTSHIP0001","testOrg1"]}' --cafile $CAFILE --tls

#Get Delivery
# {
# 	\"Owner\":\"testOrg1\",
#     \"SalesOrderID\":\"TESTSO0001\",
#     \"DeliveryNumber\":\"TESTDEL0001\"
# }
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getDelivery","{\"Owner\":\"testOrg1\",\"SalesOrderID\":\"TESTSO0001\",\"DeliveryNumber\":\"TESTDEL0001\"}","testOrg1"]}' --cafile $CAFILE --tls

    # {\"Owner\":\"testOrg1\",\"SalesOrderID\":\"TESTSO0001\",\"DeliveryNumber\":\"TESTDEL0001\"}

######################################################################################
######################## Purchase Order GR Transactions ##############################
######################################################################################
#Create PO GR
# {
#     \"PurchaseOrderID\":\"TESTPO0001\",
# 	\"LineItemNumber\":\"TESTLI0001\",
# 	\"MaterialID\":\"TESTMAT0001\",
# 	\"Quantity\":100, 
#     \"Plant\":\"TESTPLANT\",
#     \"StorageLocation\":\"TESTSLOC\",
#     \"BatchNumber\":\"TESTBATCH0001\"
# }
# testOrg2

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["reportPurchaseOrderGR","{\"PurchaseOrderID\":\"TESTPO0001\",\"LineItemNumber\":\"TESTLI0001\",\"MaterialID\":\"TESTMAT0001\",\"Quantity\":100, \"Plant\":\"TESTPLANT\",\"StorageLocation\":\"TESTSLOC\",\"BatchNumber\":\"TESTBATCH0001\"}","testOrg2"]}' --cafile $CAFILE --tls

    # {\"PurchaseOrderID\":\"TESTPO0001\",\"LineItemNumber\":\"TESTLI0001\",\"MaterialID\":\"TESTMAT0001\",\"Quantity\":100, \"Plant\":\"TESTPLANT\",\"StorageLocation\":\"TESTSLOC\",\"BatchNumber\":\"TESTBATCH0001\"}

#Get Material
# TESTMAT0001
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getMaterial","TESTMAT0001","testOrg1"]}' --cafile $CAFILE --tls

#Get Purchase Order
# {
#     \"PurchaseOrderID\":\"TESTPO0001\",
# 	\"Owner\":\"testOrg2\"
# }
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getPurchaseOrder","{\"PurchaseOrderID\":\"TESTPO0001\",\"Owner\":\"testOrg2\"}","testOrg1"]}' --cafile $CAFILE --tls

    # {\"PurchaseOrderID\":\"TESTPO0001\",\"Owner\":\"testOrg2\"}

#Get Batch
# {\"MaterialID\":\"TESTMAT0001\",\"Owner\":\"testOrg2\",\"BatchNumber\":\"TESTBATCH0001\"}
# testOrg1
docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getBatch","{\"MaterialID\":\"TESTMAT0001\",\"Owner\":\"testOrg2\",\"BatchNumber\":\"TESTBATCH0001\"}","testOrg1"]}' --cafile $CAFILE --tls

#Get Sales Order
# {
# 	\"Owner\":\"testOrg1\",
#     \"SalesOrderID\":\"TESTSO0001\"
# }
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getSalesOrder","{\"Owner\":\"testOrg1\",\"SalesOrderID\":\"TESTSO0001\"}","testOrg1"]}' --cafile $CAFILE --tls

    # {\"Owner\":\"testOrg1\",\"SalesOrderID\":\"TESTSO0001\"}

#Get Shipment
# TESTSHIP0001
# testOrg1

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["getShipment","TESTSHIP0001","testOrg1"]}' --cafile $CAFILE --tls






#Delete DATA
docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["deletePurchaseOrder","{\"PurchaseOrderID\":\"TESTPO0001\",\"Owner\":\"testOrg2\"}","testOrg2"]}' --cafile $CAFILE --tls

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["deleteProductionOrder","{\"ProductionOrderID\":\"TESTPRODORD0001\",\"Owner\":\"testOrg1\"}","testOrg1"]}' --cafile $CAFILE --tls

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["deleteBatch","{\"MaterialID\":\"TESTMAT0001\",\"Owner\":\"testOrg1\",\"BatchNumber\":\"TESTBATCH0001\"}","testOrg1"]}' --cafile $CAFILE --tls

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["deleteBatch","{\"MaterialID\":\"TESTMAT0001\",\"Owner\":\"testOrg2\",\"BatchNumber\":\"TESTBATCH0001\"}","testOrg2"]}' --cafile $CAFILE --tls

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["deleteSalesOrder","{\"Owner\":\"testOrg1\",\"SalesOrderID\":\"TESTSO0001\"}","testOrg1"]}' --cafile $CAFILE --tls

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["deleteDelivery","{\"Owner\":\"testOrg1\",\"SalesOrderID\":\"TESTSO0001\",\"DeliveryNumber\":\"TESTDEL0001\"}","testOrg1"]}' --cafile $CAFILE --tls

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["deleteShipment","TESTSHIP0001","testOrg1"]}' --cafile $CAFILE --tls

docker exec -e "CORE_PEER_TLS_ENABLED=true" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/managedblockchain-tls-chain.pem" \
    -e "CORE_PEER_ADDRESS=$PEER" -e "CORE_PEER_LOCALMSPID=$MSP" -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke -o $ORDERER -C $CHANNEL -n $CHAINCODENAME \
    -c '{"Args":["deleteMaterial","TESTMAT0001","testOrg1"]}' --cafile $CAFILE --tls