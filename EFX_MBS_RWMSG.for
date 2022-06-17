//SOCKET READS/WRITES FOR ALL CONNECTIONS
IF (Connection.SocketInstance <> 0) THEN
	Connection.Open := 1;
END_IF;

IF (Connection.Open) THEN
	//Read incoming traffic
	IF ( (MsgRead.DN OR MsgRead.ER OR ( NOT MsgRead.EN )) AND NOT Connection.ReadComplete) THEN
		MSG(MsgRead);
	END_IF;

	Connection.ONS_Read.InputBit := (Connection.ReadData.Buf.LEN > 0);
	EFX_ONS (Connection.ONS_Read);

	IF (Connection.ONS_Read.OutputBit) THEN
		Connection.ReadComplete := 1;
		NumRequests := NumRequests + 1;
	END_IF;

	//If MSG returns as error becuase socket not present or connection closed, the socket record will be erased
	Connection.ONS_ReadError.InputBit := MsgRead.ER;
	EFX_ONS(Connection.ONS_ReadError);

	Connection.Open := NOT (Connection.ONS_ReadError.OutputBit OR
		((MsgRead.ERR = 255) AND (MsgRead.EXERR = 16#0000_0033)) OR
		((MsgRead.ERR = 255) AND (MsgRead.EXERR = 16#0000_0036)) OR
		((MsgRead.ERR = 255) AND (MsgRead.EXERR = 16#0000_003D)) OR
		(MsgRead.ERR = 5));

	//If there was an error on the read/write, clear the instance to reset the connection
	//   and make it available for a new incoming connection
	IF ( NOT Connection.Open ) THEN
		Connection.SocketInstance := 0;
	END_IF;

	//Send TCP responses back to the client
	IF (Connection.Open AND Connection.WriteRequired) THEN
		MsgWrite.REQ_LEN := Connection.WriteData.Buffer.LEN + 16;
		MSG(MsgWrite);
		Connection.WriteRequired := 0;
	END_IF;

	//If MSG returns as error becuase socket not present or connection closed, the socket record will be erased
	Connection.ONS_WriteError.InputBit := MsgWrite.ER;
	EFX_ONS(Connection.ONS_WriteError);

	Connection.Open := NOT (Connection.ONS_WriteError.OutputBit OR
		((MsgWrite.ERR = 255) AND (MsgWrite.EXERR = 51)) OR
		((MsgWrite.ERR = 255) AND (MsgWrite.EXERR = 54)) OR
		((MsgWrite.ERR = 255) AND (MsgWrite.EXERR = 60)) OR
		(MsgWrite.ERR = 5));

	//If there was an error on the read/write, clear the instance to reset the connection
	//   and make it available for a new incoming connection
	IF ( NOT Connection.Open ) THEN
		Connection.SocketInstance := 0;
	END_IF;

END_IF;