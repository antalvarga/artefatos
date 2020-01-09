<!--#include file="../gen/include/SharedCache.inc" -->
<!--#include file="../gen/include/inc0000a.inc"-->
<!--#include file="../gen/include/inc0005a.inc"-->
<!--#include file="../gen/include/upload.inc"-->
<%
'=================================================================
'# C�digo/Nome (Fun��o) : Importa��o de tabela de pre�o CALOURO	
'# Programador          : Guilherme Bonis
'# Data de cria��o      : 05/01/2015
'=================================================================
%>


<%
Dim objCmd 
Dim objRS
Dim msg
Dim d
Dim byteCount
Dim UploadRequest
Dim sRetornoHtml

mensagem = ""	
linha = ""
incon = ""

Acao = request.querystring("acao")

<!--NumSeqDetalhe = request.querystring("HdnNumSeqDetalhe")-->
NumSeqPreco = request.querystring("HdnNumSeqPreco")
operacao = request.querystring("HdnOperacao")
NomeDoArquivo = request.querystring("HdnNomeDoArquivo")

ScriptExecuta = ""

if request.querystring("modulo") <> "" then
   SSession("modulo") = request.querystring("modulo")
   SSession("funcao") = request.querystring("funcao")
   SSession("titulo") = replace(request.querystring("titulo"),"$"," ")
   
   SSession("obj") = request.querystring("obj")
   SSession("rel") = request.querystring("rel")
end if




%>
<script language=javascript>
  alert( '<% response.write( Acao ) %>' );
</script>
<%			




'	 *****************************************
'	 *******     INICIO DO DELETE      *******
'	 *****************************************  

	If Acao = "deletar" Then	
	
		SQL = "BEGIN "
		
		'	 *****************************************
		'	 ******* DELETA AS INCONSIST�NCIAS  *******
		'	 *****************************************  
		
		SQL = SQL & " DELETE FROM SIA.TAB_PRE_INCON INCON "
		SQL = SQL & " WHERE INCON.NUM_SEQ_TAB_PRE_DETALHE IN "
		SQL = SQL & "       (SELECT DETALHE.NUM_SEQ_TAB_PRE_DETALHE "
		SQL = SQL & "          FROM SIA.TAB_PRE_DETALHE_PRECO DETALHE "
		SQL = SQL & "         WHERE DETALHE.NUM_SEQ_TAB_PRE_ARQUIVO_PRECO IN( "&NumSeqPreco&"));"
		
		SQL = SQL & " DELETE FROM SIA.TAB_PRE_CALOURO CALOURO "
		SQL = SQL & " WHERE CALOURO.NUM_SEQ_TAB_PRE_DETALHE IN "
		SQL = SQL & "       (SELECT DETALHE.NUM_SEQ_TAB_PRE_DETALHE "
		SQL = SQL & "          FROM SIA.TAB_PRE_DETALHE_PRECO DETALHE "
		SQL = SQL & "         WHERE DETALHE.NUM_SEQ_TAB_PRE_ARQUIVO_PRECO IN( "&NumSeqPreco&"));"		
		
		SQL = SQL & " DELETE FROM SIA.TAB_PRE_DETALHE_PRECO DETALHE "
		SQL = SQL & " WHERE DETALHE.NUM_SEQ_TAB_PRE_ARQUIVO_PRECO IN( "&NumSeqPreco & ");"
		
		SQL = SQL & " DELETE FROM SIA.TAB_PRE_ARQUIVO_PRECO WHERE NUM_SEQ_TAB_PRE_ARQUIVO_PRECO IN( "& NumSeqPreco &");"
		
		SQL = SQL & " COMMIT; END; "
		
		'objConn.execute(SQL)
		
		call Efetuar_transacao
			
	End if
	
'	 *****************************************
'	 *******     FIM DO DELETE      *******
'	 *****************************************  

Server.ScriptTimeOut = 4000000'3080000

		Dim OpenFileobj

		vNOM_TAB_PRE_ARQUIVO_PRECO = NomeDoArquivo

		'	 *****************************************
		'	 *******  INICIO INSERIR NA TABELA DE ARQUIVO: TAB_PRE_ARQUIVO_PRECO  
		'	 ***************************************** 					
		 
		SQL="SELECT SIA.S_NUM_SEQ_TAB_PRE_ARQ_PRECO.NEXTVAL NUM_SEQ_TAB_PRECO FROM DUAL"
		
		set objRS = objConn.execute(SQL)			
				
		if not objRs.eof then
			 vNUM_SEQ_TAB_PRE_ARQUIVO_PRECO = objRS("NUM_SEQ_TAB_PRECO")
			objRS.Close
		end if
		 
		vCOD_TAB_PRE_STATUS = 1  
		vCOD_TAB_PRE_RELATORIO = 3
		vIND_OPERACAO = operacao 'TipoOperacao ALTERAR      		 
		vCOD_INCLUSAO = sUser       
		vDT_INCLUSAO = "sysdate"         
		vCOD_USUARIO_EXCLUSAO = "null"
		vDT_EXCLUSAO = "null"         
		vUSUARIO_CONFIRMACAO = "null"
		vDT_CONFIRMACAO =  "null"      
		vCOD_USUARIO_LOG = sUser     
		vDT_ATUALIZA_LOG = "sysdate"    
		vTXT_IP_LOG  = s_ip_cliente         					
		
		SQL = ""
		SQL = SQL &" BEGIN "
		SQL = SQL & " INSERT INTO  SIA.TAB_PRE_ARQUIVO_PRECO ("
		SQL = SQL & " NUM_SEQ_TAB_PRE_ARQUIVO_PRECO, " 
		SQL = SQL & " COD_TAB_PRE_STATUS, "           
		SQL = SQL & " IND_OPERACAO, "                
		SQL = SQL & " COD_TAB_PRE_RELATORIO, "        
		SQL = SQL & " COD_INCLUSAO, "                
		SQL = SQL & " DT_INCLUSAO, "                
		SQL = SQL & " COD_USUARIO_EXCLUSAO, "        
		SQL = SQL & " DT_EXCLUSAO, "                 
		SQL = SQL & " USUARIO_CONFIRMACAO, "         
		SQL = SQL & " DT_CONFIRMACAO, "              
		SQL = SQL & " COD_USUARIO_LOG, "             
		SQL = SQL & " DT_ATUALIZA_LOG, "             
		SQL = SQL & " TXT_IP_LOG, " 
		SQL = SQL & " NOM_TAB_PRE_ARQUIVO_PRECO ) "                  
		SQL = SQL & " VALUES "
		SQL = SQL & "( "& vNUM_SEQ_TAB_PRE_ARQUIVO_PRECO &" , " 
		SQL = SQL & " " & vCOD_TAB_PRE_STATUS & ","
		SQL = SQL & " '" & vIND_OPERACAO & "',"
		SQL = SQL & " " & vCOD_TAB_PRE_RELATORIO & ","
		SQL = SQL & " '" & vCOD_INCLUSAO & "',"
		SQL = SQL & " " & vDT_INCLUSAO & ","						
		SQL = SQL & "' " & vCOD_USUARIO_EXCLUSAO & "',"
		SQL = SQL & " " & vDT_EXCLUSAO & ","						
		SQL = SQL & " '" & vUSUARIO_CONFIRMACAO & "',"
		SQL = SQL & " " & vDT_CONFIRMACAO & ","
		SQL = SQL & " '" & vCOD_USUARIO_LOG & "',"
		SQL = SQL & " " & vDT_ATUALIZA_LOG & ","
		SQL = SQL & " '" & vTXT_IP_LOG & "',"		
		SQL = SQL & " '" & vNOM_TAB_PRE_ARQUIVO_PRECO & "' );"			
		SQL = SQL &" COMMIT; "		
		SQL = SQL &" END; "		

		objConn.execute(SQL)				

		'	 *****************************************
		'	 *******  FIM INSERIR NA TABELA DE ARQUIVO: TAB_PRE_ARQUIVO_PRECO  
		'	 ***************************************** 


		'	 *****************************************
		'	 *******  INICIO INSERIR NA TABELA DE CALOURO: SIA.TAB_PRE_CALOURO 
		'	 *****************************************

		arquivo_path = SSession("arquivoPath")
		Set ScriptObject = Server.CreateObject("Scripting.FileSystemObject")
		linha_inserida = false

		if ScriptObject.fileExists(arquivo_path) Then 
			Set OpenFileobj = ScriptObject.OpenTextFile(arquivo_path, 1)
		'	contador = 1

			SQL = ""
			contador = 0
			Do While Not OpenFileobj.AtEndOfStream
				vLinha = OpenFileobj.ReadLine			
				
				'vetLinha = split(vLinha,Chr(59))	
				
				if contador > 0 and vLinha <> ";;;;;;;;;;;;;;;;;;;;;;;" Then

					'if UBound(vetLinha) <> "24" then ' � feita a compara��o com o n�mero 4 devido ao numero de campos que devem existir no arquivo importado
					'	Response.Write "<script> alert ('N�mero invalido de campos no arquivo " & UBound(vetLinha) & "'); document.location = 'fin2079A.asp';</script>"				
					'	Response.end
					'end if

					'	 *****************************************
					'	 *******  INICIO INSERIR NA TABELA DE CONTEUDO: SIA.TAB_PRE_CONTEUDO
					'	 ***************************************** 
					
					SQL = ""
					'SQL = SQL &" BEGIN "
					SQL = SQL  & " INSERT INTO SIA.TAB_PRE_CONTEUDO (" 
					SQL = SQL  & " NUM_SEQ_TAB_PRE_CONTEUDO , "     
					SQL = SQL  & " NUM_SEQ_TAB_PRE_ARQUIVO , "		
					SQL = SQL  & " NUM_LINHA_EXCEL ,  "               
					SQL = SQL  & " TXT_CONTEUDO) "            						
					SQL = SQL  & " VALUES  "
					SQL = SQL & "( SIA.S_TAB_PRE_CONTEUDO.NEXTVAL , " 
					SQL = SQL & " " & vNUM_SEQ_TAB_PRE_ARQUIVO_PRECO  & ","	
					SQL = SQL & " " & contador & ","
					SQL = SQL & " '" & vLinha & "')"														
					'SQL = SQL &" ; COMMIT; "		
					'SQL = SQL &" END; "	
					'SQO_INSERT_TAB_PRE_CONTEUDO = SQL
					objConn.execute(SQL)
					linha_inserida = true
					'	 *****************************************
					'	 *******  FIM INSERIR NA TABELA DE CONTEUDO: SIA.TAB_PRE_CONTEUDO 
					'	 ***************************************** 
						
				end if	
		
				contador = contador + 1

			Loop
			
			OpenFileobj.Close
			Set OpenFileobj = Nothing

			ScriptObject.DeleteFile arquivo_path, true
			
			if contador = 1 or linha_inserida = false then
				SSession("msg") = "N�o � poss�vel importar o arquivo. N�o � permitido importar arquivo que possui apenas cabe�alho."
				response.redirect "fin2079a.asp"
			end if
		Else			
			SSession("msg") = "N�o foi poss�vel localizar o arquivo para fazer a importa��o. Favor fazer uma nova importa��o."
			response.redirect "fin2079a.asp"
		End if 'ScriptObject.fileExists

		IF VerificaSeExisteArquivoNulo() = true THEN
			'Response.write true
			'response.end
			'	 *****************************************
			'	 ***** INICIO CHAMADA DA PROCEDURE PARA INSER��O DO DETALHE E CONTEUDO DE CALOURO: 	
			'    ***** SIA.TAB_PRE_CONTEUDO 
			'	 *****************************************
				
			Set objCmd = Server.CreateObject("ADODB.Command") 
			objCmd.CommandText = "SIA.FIN_ATUALIZA_TABELA_PRECO.IMPORTA_CONTEUDO_ARQUIVO"
			objCmd.CommandType = adCmdStoredProc 
			Set objCmd.ActiveConnection = ObjConn									
			objCmd.Parameters.Append objCmd.CreateParameter("P_NUM_ARQUIVO",adNumeric, adParamInput, 100,vNUM_SEQ_TAB_PRE_ARQUIVO_PRECO)
			
			objCmd.Parameters.Append objCmd.CreateParameter("P_IND_ERRO",adVarchar, adParamOutput, 2)
			objCmd.Parameters.Append objCmd.CreateParameter("P_MSG_RETORNO",adVarchar, adParamOutput, 300)			

			objCmd.Execute() 
			
			sInd_Erro = objCmd.Parameters("P_IND_ERRO").value
			sMsg_Retorno = objCmd.Parameters("P_MSG_RETORNO").value

			If sInd_Erro <> "0" Then
				SSession("msg") = sMsg_Retorno	
				objConn.close
				Set objRS = Nothing
				Set objConn = Nothing 
				Set ScriptObject = Nothing
				response.redirect "fin2079a.asp"
			End if
			
			'	 *****************************************
			'	 *******  FIM  CHAMADA DA PROCEDURE PARA INSER��O DO DETALHE E CONTEUDO DE CALOURO:
			'    *******  SIA.TAB_PRE_CONTEUDO 
			'	 *****************************************
					
			
			'	*****************************************
			'	*******  INICIO VERIFICA��O SE EXISTE ALGUM VALOR INCONSISTENTE CADASTRO DE CALOURO 
			'	*****************************************

			Set objCmd = Server.CreateObject("ADODB.Command") 
			objCmd.CommandText = "SIA.FIN_ATUALIZA_TABELA_PRECO.VERIFICA_INCON_CAD_RELATORIO"
			objCmd.CommandType = adCmdStoredProc 
			Set objCmd.ActiveConnection = ObjConn									
			objCmd.Parameters.Append objCmd.CreateParameter("P_NUM_ARQUIVO",adNumeric, adParamInput, 100, vNUM_SEQ_TAB_PRE_ARQUIVO_PRECO)
			objCmd.Parameters.Append objCmd.CreateParameter("P_TIPO_RELATORIO",adNumeric, adParamInput, 100, vCOD_TAB_PRE_RELATORIO)
			objCmd.Parameters.Append objCmd.CreateParameter("P_EXISTE_INCON", adVarchar, adParamOutput, 300)	
			
			objCmd.Execute() 
			
			sRetorno = objCmd.Parameters("P_EXISTE_INCON").value

			objConn.close
			Set objRS = Nothing
			Set objConn = Nothing 
			
			If sRetorno = "N" Then
				SSession("msg") = "Arquivo importado com sucesso!"	
			Else
				SSession("msg") = "Arquivo importado com sucesso, mas existem inconsist�ncias"
			End if
			
			Set ScriptObject = Nothing
			response.redirect "fin2079a.asp"
		Else
			objConn.close
		End if 'VerificaSeExisteArquivoNulo()
		
		Set ScriptObject = Nothing		
			
	'End if 'Upload

Set UploadRequest = Nothing

Sub Efetuar_transacao
  Set objCmd = Server.CreateObject("ADODB.Command")
  objCmd.CommandText = "SIA_SQL"
  objCmd.CommandType = adCmdStoredProc 
  Set objCmd.ActiveConnection = ObjConn
  objCmd.Parameters.Append objCmd.CreateParameter(, adVarChar, adParamInput, len(SQL), SQL)  
  objCmd.Parameters.Append objCmd.CreateParameter("retorno1", adVarchar, adParamOutput, 1)
  objCmd.Parameters.Append objCmd.CreateParameter("retorno2", adVarchar, adParamOutput, 300)
  Set objRs = objCmd.Execute()
End sub	

function c2_char(valor)
	dois_char = right("0" & valor,2)
end function

Function Filtra(myStr, tipo)

	'myStr = ucase(trim(myStr))
	'tipo  = ucase(trim(tipo))

	myStr = replace(myStr,",",".")
	'myStr = replace(myStr,"-","")
	myStr = replace(myStr,chr(13),"")

	Filtra = myStr

End Function


Function getEnviromentVariable(ByVal Variavel)
'    Declarando vari�veis
    Dim ValorVariavel
    Dim objVariavel

'    Cria��o de objetos
    Set objWSShell    = Server.CreateObject("WScript.Shell")

'    Pegando a vari�vel de ambiente
    Set objVariavel	= objWSShell.Environment("PROCESS")
    ValorVariavel		= objVariavel(Variavel)

'    Retornando a fun��o
    getEnviromentVariable = ValorVariavel

'    Destruindo os objetos
    Set objVariavel = Nothing
    Set objWSShell    = Nothing
End Function

Function VerificaSeExisteArquivoNulo()	

	retorno = false

	'	*****************************************
	'	*******  INICIO VERIFICA SE EXISTE ALGUM VALOR NULO 
	'	*****************************************

		Set objCmd = Server.CreateObject("ADODB.Command") 
		objCmd.CommandText = "SIA.FIN_ATUALIZA_TABELA_PRECO.VERIFICA_CAMPOS_NULOS"
		objCmd.CommandType = adCmdStoredProc 
		Set objCmd.ActiveConnection = ObjConn									
		objCmd.Parameters.Append objCmd.CreateParameter("P_NUM_ARQUIVO",adNumeric, adParamInput, 100,vNUM_SEQ_TAB_PRE_ARQUIVO_PRECO)				
		objCmd.Parameters.Append objCmd.CreateParameter("P_HTML", adLongVarWChar, adParamOutput, 9000000)	
		
		objCmd.Execute() 

		sRetornoHtml = objCmd.Parameters("P_HTML").value
		
		If  isNull(sRetornoHtml) or len(sRetornoHtml) = 0  Then
			retorno = true
		End if

	'	 *****************************************
	'	 *******  FIM VERIFICA SE EXISTE ALGUM VALOR NULO
	'	*****************************************
 
	VerificaSeExisteArquivoNulo = retorno
 
End Function

Set objRS = Nothing
Set objConn = Nothing 

%>
<html>	
	<head>	  
		<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
	</head>
	<!--#include file="../gen/include/inc0032b.inc"-->

	<table border="1" width="100%" align="center"> 	
		<tr> 	
			<td align="left" colspan="8"><h3 color="#ffffff">Arquivo: <%=filepathname%> n�o foi importado. Cont�m as seguintes inconsit�ncia abaixo.<h3>				
			</td>											
		</tr>				
	</table>
	<table border="1" width="100%" align="center"> 	
		<tr bgcolor="#000080">
			<td align="center" colspan="8"><font face="Arial" size="2" color="#ffffff">Linha</td>						
			<td align="center" colspan="8"><font face="Arial" size="2" color="#ffffff">Inconsist�ncias</td>			
		</tr>				
	</table>
	<table border="1" width="100%" align="center">	
		<%
			vLinhas = Split(sRetornoHtml, "-")
			
			For i = 1 to Ubound(vLinhas)
				vLinha = Split(vLinhas(i), "|")
				Response.Write "<tr><td align=left >"&vLinha(0)&"<font face='Arial' size='2' color='#ffffff'> </td><td align='center'>"&vLinha(1)&"<font face='Arial' size='2' color='#ffffff'></td></tr>"
			Next
		%>
	</table>
	<table border="1" width="100%" align="center">	
		<td align=center valign=middle>
		<hr width="97%" style="color: #000080;"/>
				<input name="Voltar" class="botao" type="button" onClick="document.location = 'fin2079A.asp';" value="Voltar">
		</td>	
	</table>

	*** ANTAL VARGA *** 

	<% 
	   response.end;
	%>
</body>
</html>