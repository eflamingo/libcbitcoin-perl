#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <ctype.h>
#include <openssl/ssl.h>
#include <openssl/ripemd.h>
#include <openssl/rand.h>
#include <CBHDKeys.h>
#include <CBChecksumBytes.h>
#include <CBAddress.h>
#include <CBWIF.h>
#include <CBByteArray.h>
#include <CBBase58.h>
#include <CBScript.h>
#include <CBTransaction.h>
#include <CBTransactionInput.h>
#include <CBTransactionOutput.h>



CBTransaction* CBTransaction_serializeddata_to_obj(char* datastring){

	CBByteArray* data = hexstring_to_bytearray(datastring);

	CBTransaction* tx = CBNewTransactionFromData(data);
	uint32_t dlen = CBTransactionDeserialise(tx);

	//CBDestroyByteArray(data);
	return tx;
}

char* CBTransaction_obj_to_serializeddata(CBTransaction * tx){
	CBTransactionPrepareBytes(tx);
	int dlen = CBTransactionSerialise(tx,1);
	CBByteArray* serializeddata = CBGetMessage(tx)->bytes;

	char* answer = bytearray_to_hexstring(serializeddata,dlen);

	return answer;
}



//////////////////////// perl export functions /////////////
//CBTransactionInput * CBNewTransactionInput(CBScript * script, uint32_t sequence, CBByteArray * prevOutHash, uint32_t prevOutIndex)

char* create_tx_obj(int lockTime, int version, SV* inputs, SV* outputs, int numOfInputs, int numOfOutputs){
	CBTransaction* tx = CBNewTransaction((uint32_t) lockTime, (uint32_t) version);

	int n;
	int in_length, out_length;
    if ((! SvROK(inputs))
    || (SvTYPE(SvRV(inputs)) != SVt_PVAV)
    || ((in_length = av_len((AV *)SvRV(inputs))) < 0))
    {
        return 0;
    }
    if ((! SvROK(outputs))
    || (SvTYPE(SvRV(outputs)) != SVt_PVAV)
    || ((out_length = av_len((AV *)SvRV(outputs))) < 0))
    {
        return 0;
    }

    // load TransactionInput
	for (n=0; n<=in_length; n++) {
		STRLEN l;

		char * fn = SvPV (*av_fetch ((AV *) SvRV (inputs), n, 0), l);
		CBTransactionInput * inx = CBTransactionInput_serializeddata_to_obj(fn);
		CBTransactionAddInput(tx,inx);
	}
	for (n=0; n<=out_length; n++) {
		STRLEN l;

		char * fn = SvPV (*av_fetch ((AV *) SvRV (outputs), n, 0), l);
		CBTransactionOutput * outx = CBTransactionOutput_serializeddata_to_obj(fn);
		CBTransactionAddOutput(tx,outx);
	}
	char* answer = CBTransaction_obj_to_serializeddata(tx);
	//CBFreeTransaction(tx);
	return answer;
}

int get_numOfInputs(char* serializedDataString){
	CBTransaction* tx = CBTransaction_serializeddata_to_obj(serializedDataString);
	uint32_t numOfInputs = tx->inputNum;
	CBFreeTransaction(tx);
	return (int)numOfInputs;	
}
int get_numOfOutputs(char* serializedDataString){
	CBTransaction* tx = CBTransaction_serializeddata_to_obj(serializedDataString);
	uint32_t numOfOutputs = tx->outputNum;
	CBFreeTransaction(tx);
	return (int)numOfOutputs;
}
char* get_Input(char* serializedDataString,int InputIndex){
	CBTransaction* tx = CBTransaction_serializeddata_to_obj(serializedDataString);
	CBTransactionInput** inputs = tx->inputs;
	char* answer = CBTransactionInput_obj_to_serializeddata(inputs[InputIndex]);
	CBFreeTransaction(tx);
	return answer;
}
char* get_Output(char* serializedDataString,int OutputIndex){
	CBTransaction* tx = CBTransaction_serializeddata_to_obj(serializedDataString);
	CBTransactionOutput** outputs = tx->outputs;
	char* answer = CBTransactionOutput_obj_to_serializeddata(outputs[OutputIndex]);
	CBFreeTransaction(tx);
	return answer;
}

char* hash_of_tx(char* serializedDataString){
	CBTransaction* tx = CBTransaction_serializeddata_to_obj(serializedDataString);
	CBByteArray * data = CBNewByteArrayWithData(CBTransactionGetHash(tx), (uint32_t)32);
	CBFreeTransaction(tx);
	return bytearray_to_hexstring(data,32);
}

int get_lockTime_from_obj(char* serializedDataString){
	CBTransaction* tx = CBTransaction_serializeddata_to_obj(serializedDataString);
	uint32_t lockTime = tx->lockTime;
	CBFreeTransaction(tx);
	return (int)lockTime;
}

int get_version_from_obj(char* serializedDataString){
	CBTransaction* tx = CBTransaction_serializeddata_to_obj(serializedDataString);
	uint32_t version = tx->version;
	CBFreeTransaction(tx);
	return (int)version;
}
// CBTransaction * self, CBKeyPair * key, CBByteArray * prevOutSubScript, uint32_t input, CBSignType signType
char* sign_tx_pubkeyhash(char* txString, char* keypairString, char* prevOutSubScriptString, int input, char* signTypeString){
        //CBLogError("sign 0.");
	//fprintf(stderr, "sign 0.");
	CBTransaction * tx = CBTransaction_serializeddata_to_obj(txString);
        //fprintf(stderr, "sign 0.1");
	CBHDKey * keypair = CBHDKey_serializeddata_to_obj(keypairString);
        //fprintf(stderr, "sign 0.2");
	//CBScript * prevOutSubScript = CBScript_serializeddata_to_obj(prevOutSubScriptString);
	CBScript * prevOutSubScript = tx->inputs[input]->scriptObject;
	//CBLogError("sign 1.");
	// figure out the signature type
	CBSignType signtype;
	if (strcmp(signTypeString, "CB_SIGHASH_ALL") == 0) {
		signtype = CB_SIGHASH_ALL;
	}
	else if(strcmp(signTypeString, "CB_SIGHASH_NONE") == 0){
		signtype = CB_SIGHASH_NONE;
	}
	else if(strcmp(signTypeString, "CB_SIGHASH_SINGLE") == 0){
		signtype = CB_SIGHASH_SINGLE;
	}
	else if(strcmp(signTypeString, "CB_SIGHASH_ANYONECANPAY") == 0){
		signtype = CB_SIGHASH_ANYONECANPAY;
	}
	else{
		// we have to fail here
		return "NULL";
	}
        //CBLogError("sign 2.(%d)",input);
/*
	CBTransactionSignPubKeyHashInput(
		tx
		,keypair->keyPair
		, prevOutSubScript
		, (uint32_t)input
		, CB_SIGHASH_ALL
	);*/
	CBScript * oldprevOutSubScript = tx->inputs[input]->scriptObject;
        //CBLogError("sign 3.");
	if (!CBTransactionSignPubKeyHashInput(tx, keypair->keyPair,
			oldprevOutSubScript, input, signtype)){
		CBLogError("Unable to add a signature to a pubkey hash transaction input.");
		return "NULL";
	}
/*
	tx->inputs[input]->scriptObject = CBNewScriptOfSize(CB_PUBKEY_SIZE + CB_MAX_DER_SIG_SIZE + 3);
	uint8_t sigLen = CBTransactionAddSignature(tx, tx->inputs[input]->scriptObject, 0,
			keypair->keyPair, oldprevOutSubScript, input, signtype);
	if (!sigLen){
		CBLogError("Unable to add a signature to a pubkey hash transaction input.");
		return "NULL";
	}

	// add the public key
	CBByteArraySetByte(tx->inputs[input]->scriptObject, sigLen, CB_PUBKEY_SIZE);
	memcpy(CBByteArrayGetData(tx->inputs[input]->scriptObject) + sigLen + 1, keypair->keyPair->pubkey.key, CB_PUBKEY_SIZE);
	//return txString;
*/
	return CBTransaction_obj_to_serializeddata(tx);

}
bool CBTransactionSignMultisigInputV2(CBTransaction * self, CBKeyPair * key, CBByteArray * prevOutSubScript, uint32_t input, CBSignType signType) {
	CBScript * inScript;
	uint16_t offset;
	if (self->inputs[input]->scriptObject) {
		offset = self->inputs[input]->scriptObject->length;
		inScript = CBNewByteArrayOfSize(offset + CB_MAX_DER_SIG_SIZE + 2);
		CBByteArrayCopyByteArray(inScript, 0, self->inputs[input]->scriptObject);
		CBReleaseObject(self->inputs[input]->scriptObject);
		self->inputs[input]->scriptObject = inScript;
	}else{
		inScript = self->inputs[input]->scriptObject = CBNewScriptOfSize(CB_MAX_DER_SIG_SIZE + 3);
		CBByteArraySetByte(inScript, 0, CB_SCRIPT_OP_0);
		offset = 1;
	}
	return CBTransactionAddSignature(self, inScript, offset, key, prevOutSubScript, input, signType);
}

char* sign_tx_multisig(char* txString, char* keypairString, char* prevOutSubScriptString, int input, char* signTypeString){
	CBTransaction * tx = CBTransaction_serializeddata_to_obj(txString);
	CBHDKey * keypair = CBHDKey_serializeddata_to_obj(keypairString);
	//CBScript * prevOutSubScript = CBScript_serializeddata_to_obj(prevOutSubScriptString);
	CBScript * prevOutSubScript = CBByteArrayCopy((CBByteArray*) tx->inputs[input]->scriptObject);


	// figure out the signature type
	CBSignType signtype;
	if (strcmp(signTypeString, "CB_SIGHASH_ALL") == 0) {
		signtype = CB_SIGHASH_ALL;
	}
	else if(strcmp(signTypeString, "CB_SIGHASH_NONE") == 0){
		signtype = CB_SIGHASH_NONE;
	}
	else if(strcmp(signTypeString, "CB_SIGHASH_SINGLE") == 0){
		signtype = CB_SIGHASH_SINGLE;
	}
	else if(strcmp(signTypeString, "CB_SIGHASH_ANYONECANPAY") == 0){
		signtype = CB_SIGHASH_ANYONECANPAY;
	}
	else{
		// we have to fail here
		return "NULL";
	}

	//CBScript * oldprevOutSubScript = tx->inputs[input]->scriptObject;
	/*
	 * CBTransactionSignMultisigInput(
			CBTransaction * self, CBKeyPair * key, CBByteArray * prevOutSubScript, uint32_t input, CBSignType signType
		)
	 */
	if (!CBTransactionSignMultisigInputV2(tx, keypair->keyPair, prevOutSubScript, input, signtype)){
		CBLogError("Unable to add a signature to a pubkey hash transaction input.");
		return "NULL";
	}

	return CBTransaction_obj_to_serializeddata(tx);
}

char* addredeemscript(char* txString, char* redeemScript,int input){
	// CBTransactionAddP2SHScript(CBTransaction * self, CBScript * p2shScript, uint32_t input)
	CBTransaction * self = CBTransaction_serializeddata_to_obj(txString);
	//fprintf(stderr,"...part 3.1\n...script=%s\n",redeemScript);
	CBScript * p2shScript = CBNewScriptFromString(redeemScript);
	//CBTransactionAddP2SHScript(self, tx_stringToScript(redeemScript),(uint32_t) index);
	//fprintf(stderr,"...part 3.2\n");
	uint16_t offset = self->inputs[input]->scriptObject->length;
	//fprintf(stderr,"...part 3.3 with offset=%d\n",offset);
	CBScript * inScript = CBNewByteArrayOfSize(offset + p2shScript->length + CBScriptGetLengthOfPushOp(p2shScript->length));
	//fprintf(stderr,"...part 4\n");
	CBByteArrayCopyByteArray(inScript, 0, self->inputs[input]->scriptObject);
	//fprintf(stderr,"...part 5\n");
	CBReleaseObject(self->inputs[input]->scriptObject);
	//fprintf(stderr,"...part 6\n");
	self->inputs[input]->scriptObject = inScript;
	//fprintf(stderr,"...part 7\n");
	CBScriptWritePushOp(inScript, offset, CBByteArrayGetData(p2shScript), p2shScript->length);
	return CBTransaction_obj_to_serializeddata(self);
}


MODULE = CBitcoin::Transaction	PACKAGE = CBitcoin::Transaction	

PROTOTYPES: DISABLE




char *
create_tx_obj (lockTime, version, inputs, outputs, numOfInputs, numOfOutputs)
	int	lockTime
	int	version
	SV *	inputs
	SV *	outputs
	int	numOfInputs
	int	numOfOutputs

int
get_numOfInputs (serializedDataString)
	char *	serializedDataString

int
get_numOfOutputs (serializedDataString)
	char *	serializedDataString

char *
get_Input (serializedDataString, InputIndex)
	char *	serializedDataString
	int	InputIndex

char *
get_Output (serializedDataString, OutputIndex)
	char *	serializedDataString
	int	OutputIndex

char *
hash_of_tx (serializedDataString)
	char *	serializedDataString

int
get_lockTime_from_obj (serializedDataString)
	char *	serializedDataString

int
get_version_from_obj (serializedDataString)
	char *	serializedDataString

char *
sign_tx_pubkeyhash (txString, keypairString, prevOutSubScriptString, input, signTypeString)
	char *	txString
	char *	keypairString
	char *	prevOutSubScriptString
	int	input
	char *	signTypeString

char *
sign_tx_multisig (txString, keypairString, prevOutSubScriptString, input, signTypeString)
	char *	txString
	char *	keypairString
	char *	prevOutSubScriptString
	int	input
	char *	signTypeString

char *
addredeemscript(txString,redeemScript,input)
	char * txString
	char * redeemScript
	int input
