package main

import (
	"encoding/json"
	"fmt"
	"bytes"
	"strconv"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	pb "github.com/hyperledger/fabric-protos-go/peer"
)



// SmartContract provides functions for managing an Asset
type SmartContract struct {

}

type Organization struct {
	ResourceType	string	`json:"resourceType"`
	Identifier		string	`json:"identifier"`
	Name			string	`json:"name"`
}

type Agent struct {
	Type	string			`json:"type"`
	Role	string			`json:"role"`
	Who		Organization	`json:"who"`
}

type Detail struct {
	Type			string		`json:"type"`
	Value			string		`json:"value"`
}

type Entity struct {
	ResourceType	string	`json:"resourceType"`
	Identifier		string	`json:"identifier"`
	Detail			Detail	`json:"detail"`
}

type Asset struct {
	Identifier		string					`json:"identifier"`
	ResourceType	string					`json:"resourceType"`
	Type			string					`json:"type"`
	Action			string					`json:"action"`
	Recorded		string					`json:"recorded"`
	PurposeOfEvent	string					`json:"purposeOfEvent"`
	Agent1			Agent					`json:"agent1"`
	Agent2			Agent					`json:"agent2"`
	Source			Organization			`json:"source"`
	Entity			Entity					`json:"entity"`
}

func main() {
	err := shim.Start(new(SmartContract))
	if err != nil {
		fmt.Printf("Error starting SmartContract - %s", err)
	}
}


func (s *SmartContract) Init(stub shim.ChaincodeStubInterface) pb.Response {
    return shim.Success(nil)
}

func (s *SmartContract) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	fmt.Println(" ")
	fmt.Println("starting invoke, for - " + function)

	// Handle different functions
	if function == "init" {                    
		return s.Init(stub)
	} else if function == "readBySource" {             
		return s.GetAssetsBySourceOrg(stub, args)
	} else if function == "readByDestination" {             
		return s.GetAssetsByDestinationOrg(stub, args)
	} else if function == "readByDate" {             
		return s.GetAssetsByEndDate(stub, args)
	} else if function == "readByPatient" {             
		return s.GetAssetsByPatient(stub, args)
	} else if function == "newTransaction" {            
		return s.CreateAsset(stub, args)
	} else if function == "readAll" {            
		return s.GetAllAssets(stub, args)
	} 
	
	// error out
	fmt.Println("Received unknown invoke function name - " + function)
	return shim.Error("Received unknown invoke function name - '" + function + "'")
}



// CreateAsset issues a new asset to the world state with given details.

func (s *SmartContract) CreateAsset(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var err error
	exists, err := stub.GetState(args[0])
	if err != nil {
		return shim.Error("Error while ckecking if asset exists." + err.Error())
	} else if exists != nil {
		return shim.Error("Asset already exists")

	}

	if len(args)!=9{
        return shim.Error("Incorrect number of arguments. Expecting 9. Received: " + strconv.Itoa(len(args)))
    }

	var identifier = args[0]
	var idOrgS = args[1]
	var nameOrgS = args[2]
	var idOrgD = args[3]
	var nameOrgD = args[4]
	var validityDate = args[5]
	var idPatient = args[6]
	var purpose = args[7]
	var recorded = args[8]

	sourceOrg := Organization{
		ResourceType:	"Organization",
		Identifier:		idOrgS,
		Name:			nameOrgS,
	}

	destOrg := Organization{
		ResourceType:	"Organization",
		Identifier:		idOrgD,
		Name:			nameOrgD,
	}

	agent1 := Agent{
		Type:	"PROV",
		Role:	"AUT",
		Who:	sourceOrg,
	}

	agent2 := Agent{
		Type:	"PROV",
		Role:	"IRCP",
		Who:	destOrg,
	}

	detail := Detail{
		Type:	"End of validity period date",
		Value:	validityDate,
	}

	entity := Entity{
		ResourceType:	"Patient", 
		Identifier:		idPatient,
		Detail:			detail,
	}

	asset := Asset{
		Identifier:			identifier,
		ResourceType:		"AuditEvent",
		Type:				"receive",
		Action:				"C",
		Recorded:			recorded,
		PurposeOfEvent:		purpose,
		Agent1:				agent1,
		Agent2:				agent2,
		Source:				sourceOrg,
		Entity:				entity,
	}

	assetAsBytes, err := json.Marshal(asset)
	if err != nil {
		return shim.Error(err.Error())
	}

	err = stub.PutState(asset.Identifier, assetAsBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	CompKeySource := "sourceOrg~indentifier"
	sourceIndexKey, err := stub.CreateCompositeKey(CompKeySource, []string{asset.Agent1.Who.Name, asset.Identifier})
	if err != nil {
		return shim.Error(err.Error())
	}
	//  Save index entry to world state. Only the key name is needed, no need to store a duplicate copy of the asset.
	//  Note - passing a 'nil' value will effectively delete the key from state, therefore we pass null character as value
	value := []byte{0x00}
	err = stub.PutState(sourceIndexKey, value)
	if err != nil {
		return shim.Error(err.Error())
	}

	CompKeyDest := "destOrg~indentifier"
	destIndexKey, err := stub.CreateCompositeKey(CompKeyDest, []string{asset.Agent2.Who.Name, asset.Identifier})
	if err != nil {
		return shim.Error(err.Error())
	}
	err = stub.PutState(destIndexKey, value)
	if err != nil {
		return shim.Error(err.Error())
	}

	CompKeyEnd := "validityEnd~indentifier"
	endIndexKey, err := stub.CreateCompositeKey(CompKeyEnd, []string{asset.Entity.Detail.Value, asset.Identifier})
	if err != nil {
		return shim.Error(err.Error())
	}
	err = stub.PutState(endIndexKey, value)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(nil)
}

func (s *SmartContract) GetAllAssets(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	resultsIterator, err := stub.GetStateByRange("", "")
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()

	var assets []*Asset
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return shim.Error(err.Error())
		}

		var asset Asset
		err = json.Unmarshal(queryResponse.Value, &asset)
		if err != nil {
			return shim.Error(err.Error())
		}
		assets = append(assets, &asset)
	}

	assetAsBytes, err := json.Marshal(assets)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(assetAsBytes)
}

func (s *SmartContract) GetAssetsBySourceOrg(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1 (Source Organization name).")
	}

	sourceOrg := args[0]
	CompKey := "sourceOrg~indentifier"
	resultsIterator, err := stub.GetStateByPartialCompositeKey(CompKey, []string{sourceOrg})
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()

	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return shim.Error(err.Error())
		}
		_, compositeKeyParts, err := stub.SplitCompositeKey(queryResponse.Key)
		if err != nil {
			return shim.Error(err.Error())
		}


		returnedAssetID := compositeKeyParts[1]
		assetAsBytes, err := stub.GetState(returnedAssetID)
		if err != nil {
			return shim.Error(err.Error())
		}
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"Key\":")
		buffer.WriteString("\"")
		buffer.WriteString(returnedAssetID)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(assetAsBytes))
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}

	buffer.WriteString("]")

	return shim.Success(buffer.Bytes())
} 

func (s *SmartContract) GetAssetsByDestinationOrg(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1 (Destination Organization name).")
	}

	destOrg := args[0]
	CompKey := "destOrg~indentifier"
	resultsIterator, err := stub.GetStateByPartialCompositeKey(CompKey, []string{destOrg})
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()

	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return shim.Error(err.Error())
		}
		_, compositeKeyParts, err := stub.SplitCompositeKey(queryResponse.Key)
		if err != nil {
			return shim.Error(err.Error())
		}


		returnedAssetID := compositeKeyParts[1]
		assetAsBytes, err := stub.GetState(returnedAssetID)
		if err != nil {
			return shim.Error(err.Error())
		}
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"Key\":")
		buffer.WriteString("\"")
		buffer.WriteString(returnedAssetID)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(assetAsBytes))
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}

	buffer.WriteString("]")

	return shim.Success(buffer.Bytes())
} 

func (s *SmartContract) GetAssetsByEndDate(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1 (End of validity period date).")
	}

	validityEnd := args[0]
	CompKey := "validityEnd~indentifier"
	resultsIterator, err := stub.GetStateByPartialCompositeKey(CompKey, []string{validityEnd})
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()

	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return shim.Error(err.Error())
		}
		_, compositeKeyParts, err := stub.SplitCompositeKey(queryResponse.Key)
		if err != nil {
			return shim.Error(err.Error())
		}


		returnedAssetID := compositeKeyParts[1]
		assetAsBytes, err := stub.GetState(returnedAssetID)
		if err != nil {
			return shim.Error(err.Error())
		}
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"Key\":")
		buffer.WriteString("\"")
		buffer.WriteString(returnedAssetID)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(assetAsBytes))
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}

	buffer.WriteString("]")

	return shim.Success(buffer.Bytes())
} 

func (s *SmartContract) GetAssetsByPatient(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1 (Patient ID).")
	}

	idPatient := args[0]
	CompKey := "idPatient~indentifier"
	resultsIterator, err := stub.GetStateByPartialCompositeKey(CompKey, []string{idPatient})
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()

	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return shim.Error(err.Error())
		}
		_, compositeKeyParts, err := stub.SplitCompositeKey(queryResponse.Key)
		if err != nil {
			return shim.Error(err.Error())
		}


		returnedAssetID := compositeKeyParts[1]
		assetAsBytes, err := stub.GetState(returnedAssetID)
		if err != nil {
			return shim.Error(err.Error())
		}
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"Key\":")
		buffer.WriteString("\"")
		buffer.WriteString(returnedAssetID)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(assetAsBytes))
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}

	buffer.WriteString("]")

	return shim.Success(buffer.Bytes())
} 