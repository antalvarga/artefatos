





function Open() {

    var xfileName = document.getElementById("file-input").value;
    var fileName = xfileName.substr(xfileName.lastIndexOf('\\') + 1);
    var pathName = xfileName.substr(0, xfileName.lastIndexOf('\\'));

    // document.getElementById("<%=txtCaminho.ClientID%>").value = fileName.toUpperCase();
    //document.getElementById("arquivoEscolhido").value = fileName;

    // document.querySelector("#arquivoEscolhido").text = fileName;
    //alert(xfileName);
    //alert(pathName);

    //var confirma = confirm("Confirma o carregamento do arquivo" + filename  + " ? ");

    //var confirma = confirm("Confirma o carregamento do arquivo " + fileName + " ? ") ;
    return confirm("Confirma o carregamento do arquivo " + fileName + " ? ") ;
    //return confirma;
}
