DECLARE
  V_NSEQ_ALUNO_CURSO    NUMBER;
  V_NSEQ_CARNE          NUMBER;
  V_VAL_A_PAGAR         NUMBER;
  V_COD_MATRICULA       VARCHAR2(20);
  V_DT_MES_ANO_COMPETENCIA DATE;
  -----------------------
  V_COUNT_PENDENTES     NUMBER(1);
  V_COUNT_APROPRIADOS   NUMBER(1);
  V_COUNT_QUITADOS      NUMBER(1);
  -----------------------
  V_NSEQ_ACORDO_ESPECIAL SIA.ACORDO_ESPECIAL_TITULOS.NUM_SEQ_ACORDO_ESPECIAL%TYPE;
  V_COD_INSTITUICAO      SIA.INSTITUICAO_ENSINO.COD_INSTITUICAO%TYPE;
  -----------------------
  P_IND_ERRO            VARCHAR2(1);
  P_MSG_RETORNO         VARCHAR2(1000);
  -----------------------
  V_NUM_SEQ_CENARIO_EXECUCAO  NUMBER(10);
  V_CONT                NUMBER(10);
  ERR_PREVISTO          EXCEPTION;
  -----------------------
  V_MIN_DEB_PEND        NUMBER(10);
  V_POSICAO             PLS_INTEGER;
  --
  V_DATE                 DATE;
  V_ALUNO_ATUAL          NUMBER;
  V_SEQ                  NUMBER(5);
  V_SQL_CARNE            VARCHAR2(1000);
  V_VALOR_A_RECEBER      NUMBER;
  
  TYPE R_DADOS_CARNE IS RECORD
    (
      DT_MES_ANO_COMPETENCIA  DATE,
      --IND_TIPO_CARNE          SIA.CARNE.IND_TIPO_CARNE%TYPE,
      DT_VENCIMENTO           DATE
      --NUM_SEQ_ALUNO_CURSO     SIA.ALUNO_CURSO.NUM_SEQ_ALUNO_CURSO%TYPE,
      --NUM_SEQ_CANDIDATO       SIA.CANDIDATO.NUM_SEQ_CANDIDATO%TYPE
      
    );
    
  TYPE T_DADOS_CARNE IS TABLE OF R_DADOS_CARNE;
  T_CARNE_REGERAR T_DADOS_CARNE := T_DADOS_CARNE();
  
  

  -- OBTÉM AS PARCELAS QUE ESTÃO EM DUPLICIDADE
  CURSOR C_DUPLICIDADES IS
  --ALUNO
    SELECT DISTINCT AC.COD_MATRICULA,
                    AC.NUM_SEQ_ALUNO,
                    ACET.NUM_SEQ_ACORDO_ESPECIAL, 
                    CAR2.NUM_SEQ_CARNE NSEQ_CARNE_ORIG,
                    CAR2.VAL_A_PAGAR VAL_A_PAGAR_ORIG, 
                    AC.NUM_SEQ_ALUNO_CURSO,
                    AC.NUM_SEQ_CANDIDATO,
                    DM.COD_MOEDA,
                    PA.DT_INI_PERIODO, 
                    CAR2.DT_MES_ANO_COMPETENCIA as DT_MES_ANO_COMPETENCIA, 
                    AC.COD_SITUACAO_ALUNO, 
                    CAR2.IND_TIPO_CARNE, 
                    DM.VAL_A_RECEBER,
                    CAR2.DT_VENCIMENTO
      FROM sia.ACORDO_ESPECIAL_TITULOS ACET
          ,SIA.DEBITO_MENSALIDADE DM
          ,SIA.DEBITO_CREDITO_CONSUMIDO DCC
          ,SIA.CARNE CAR
          ,SIA.ALUNO_CURSO AC
          ,SIA.ACORDO_ESPECIAL ACO
          ,SIA.ACORDO_ESPECIAL_TITULOS AET2
          ,SIA.CARNE CAR2
          ,SIA.PERIODO_ACADEMICO PA
    WHERE ACET.NUM_SEQ_DEBITO_MENSALIDADE = DM.NUM_SEQ_DEBITO_MENSALIDADE
      AND DM.NUM_SEQ_DEBITO_MENSALIDADE = DCC.NUM_SEQ_DEBITO_MENSALIDADE (+)
      AND DCC.NUM_SEQ_CARNE = CAR.NUM_SEQ_CARNE (+)
      AND AET2.NUM_SEQ_ACORDO_ESPECIAL = ACET.NUM_SEQ_ACORDO_ESPECIAL
      AND AET2.IND_RELACAO = 0
      AND CAR2.NUM_SEQ_CARNE = AET2.NUM_SEQ_CARNE
      AND DM.NUM_SEQ_ALUNO_CURSO = AC.NUM_SEQ_ALUNO_CURSO
      AND PA.NUM_SEQ_PERIODO_ACADEMICO = (select SIA.PERIODO_ATUAL_ALUNO(AC.NUM_SEQ_ALUNO_CURSO) FROM DUAL)
      AND ACET.NUM_SEQ_ACORDO_ESPECIAL = ACO.NUM_SEQ_ACORDO_ESPECIAL
      AND AC.COD_MATRICULA IN ('201809124093','201809166331')
      AND ACET.IND_RELACAO = 2
      AND DM.IND_SITUACAO_DEBITO <> '3'
      AND DM.NUM_SEQ_ALUNO_CURSO IS NOT NULL
      AND DM.DT_MES_ANO_REFERENCIA BETWEEN TO_DATE('01/01/2017', 'DD/MM/YYYY') AND TO_DATE('01/12/2030', 'DD/MM/YYYY')
      AND ACO.NUM_SEQ_CONTRATO_PARCELAMENTO IS NULL
      AND ACO.IND_SITUACAO = 8
      AND EXISTS (SELECT 1
                    FROM SIA.DEBITO_MENSALIDADE DM2
              INNER JOIN SIA.ACORDO_ESPECIAL_TITULOS AET2 ON AET2.NUM_SEQ_DEBITO_MENSALIDADE = DM2.NUM_SEQ_DEBITO_MENSALIDADE
                   WHERE DM2.NUM_SEQ_ALUNO_CURSO = DM.NUM_SEQ_ALUNO_CURSO
                     AND DM2.COD_MOTIVO_DEBITO = DM.COD_MOTIVO_DEBITO
                     AND DM2.IND_SITUACAO_DEBITO <> '3'
                     AND DM2.DT_MES_ANO_REFERENCIA = DM.DT_MES_ANO_REFERENCIA
                     AND DM2.ROWID < DM.ROWID
                     AND DM2.COD_MOTIVO_DEBITO in (77,78)
                     AND AET2.NUM_SEQ_ACORDO_ESPECIAL = ACET.NUM_SEQ_ACORDO_ESPECIAL
                  )
      AND NOT EXISTS (SELECT 1 FROM SIA.CREDITO_MENSALIDADE CM 
                              WHERE CM.DT_MES_ANO_REFERENCIA BETWEEN TO_DATE('01/02/2019', 'DD/MM/YYYY') AND TO_DATE('31/08/2019', 'DD/MM/YYYY')
                                AND CM.COD_MOTIVO_CREDITO = 113
                                AND CM.NUM_SEQ_ALUNO_CURSO = DM.NUM_SEQ_ALUNO_CURSO 
                     )
                            
    UNION ALL
   --CANDIDATO
    SELECT DISTINCT AC.COD_MATRICULA,
                    AC.NUM_SEQ_ALUNO,
                    ACET.NUM_SEQ_ACORDO_ESPECIAL, 
                    CAR2.NUM_SEQ_CARNE NSEQ_CARNE_ORIG,
                    CAR2.VAL_A_PAGAR VAL_A_PAGAR_ORIG, 
                    AC.NUM_SEQ_ALUNO_CURSO,
                    AC.NUM_SEQ_CANDIDATO,
                    DM.COD_MOEDA,
                    PA.DT_INI_PERIODO, 
                    CAR2.DT_MES_ANO_COMPETENCIA AS DT_MES_ANO_COMPETENCIA, 
                    AC.COD_SITUACAO_ALUNO, 
                    CAR2.IND_TIPO_CARNE, 
                    DM.VAL_A_RECEBER,
                    CAR2.DT_VENCIMENTO
      FROM sia.ACORDO_ESPECIAL_TITULOS ACET
          ,SIA.DEBITO_MENSALIDADE DM
          ,SIA.DEBITO_CREDITO_CONSUMIDO DCC
          ,SIA.CARNE CAR
          ,SIA.ALUNO_CURSO AC
          ,SIA.ACORDO_ESPECIAL ACO
          ,SIA.ACORDO_ESPECIAL_TITULOS AET2
          ,SIA.CARNE CAR2
          ,SIA.PERIODO_ACADEMICO PA
    WHERE ACET.NUM_SEQ_DEBITO_MENSALIDADE = DM.NUM_SEQ_DEBITO_MENSALIDADE
      AND DM.NUM_SEQ_DEBITO_MENSALIDADE = DCC.NUM_SEQ_DEBITO_MENSALIDADE (+)
      AND DCC.NUM_SEQ_CARNE = CAR.NUM_SEQ_CARNE (+)
      AND AET2.NUM_SEQ_ACORDO_ESPECIAL = ACET.NUM_SEQ_ACORDO_ESPECIAL
      AND AET2.IND_RELACAO = 0
      AND CAR2.NUM_SEQ_CARNE = AET2.NUM_SEQ_CARNE
      AND DM.NUM_SEQ_CANDIDATO = AC.NUM_SEQ_CANDIDATO
      AND PA.NUM_SEQ_PERIODO_ACADEMICO = (select SIA.PERIODO_ATUAL_ALUNO(AC.NUM_SEQ_ALUNO_CURSO) FROM DUAL)
      AND AC.COD_MATRICULA IN ('201809124093','201809166331')
      AND ACET.IND_RELACAO = 2
      AND DM.IND_SITUACAO_DEBITO <> '3'
      AND DM.DT_MES_ANO_REFERENCIA BETWEEN TO_DATE('01/01/2017', 'DD/MM/YYYY') AND TO_DATE('01/12/2030', 'DD/MM/YYYY')
      AND ACO.IND_SITUACAO = 8
      AND EXISTS (SELECT 1
                FROM SIA.DEBITO_MENSALIDADE DM2
               INNER JOIN SIA.ACORDO_ESPECIAL_TITULOS AET3 ON AET3.NUM_SEQ_DEBITO_MENSALIDADE = DM2.NUM_SEQ_DEBITO_MENSALIDADE
                WHERE DM2.NUM_SEQ_CANDIDATO = DM.NUM_SEQ_CANDIDATO
                  AND DM2.COD_MOTIVO_DEBITO = DM.COD_MOTIVO_DEBITO
                  AND DM2.IND_SITUACAO_DEBITO <> '3'
                  AND DM2.DT_MES_ANO_REFERENCIA = DM.DT_MES_ANO_REFERENCIA
                  AND DM2.ROWID < DM.ROWID
                  AND DM2.COD_MOTIVO_DEBITO in (77,78)
                  AND AET3.NUM_SEQ_ACORDO_ESPECIAL = ACET.NUM_SEQ_ACORDO_ESPECIAL
                  )
       AND NOT EXISTS (SELECT 1 FROM SIA.CREDITO_MENSALIDADE CM 
                            WHERE CM.DT_MES_ANO_REFERENCIA BETWEEN TO_DATE('01/02/2019', 'DD/MM/YYYY') AND TO_DATE('31/08/2019', 'DD/MM/YYYY')
                            AND CM.COD_MOTIVO_CREDITO = 113
                            AND CM.NUM_SEQ_CANDIDATO = DM.NUM_SEQ_CANDIDATO 
                    );
   
       
    R_DUPLICIDADES C_DUPLICIDADES%ROWTYPE;
BEGIN

   -- AJUSTA O USUÁRIO
   DBMS_APPLICATION_INFO.SET_CLIENT_INFO('1016283@estacio');
   
   -- INSERE LINHA DE LOG NA EXECUÇÃO DO CENÁRIO
    V_NUM_SEQ_CENARIO_EXECUCAO            := SIA.S_DIS_CENARIO_EXECUCAO.NEXTVAL;
    INSERT INTO SIA.DIS_CENARIO_EXECUCAO 
           (NUM_SEQ_CENARIO, COD_CENARIO, NOM_FANTASIA, DATA, DILUICAO_DIS, CONFLITO, CAR_ESPECIAL, REMANEJO, TI, CANC_MATRICULA, CENARIO)
    VALUES (V_NUM_SEQ_CENARIO_EXECUCAO, 'CR45', '-', SYSDATE, R_DUPLICIDADES.NUM_SEQ_ACORDO_ESPECIAL, '-', R_DUPLICIDADES.NSEQ_CARNE_ORIG, '-', '-', '-' , 'DUPLICIDADE');
    -- 
   
  IF NOT C_DUPLICIDADES%ISOPEN THEN 
    OPEN C_DUPLICIDADES; 
  END IF; 
  
  V_ALUNO_ATUAL := 0;
  V_SEQ         := 1;
  
  LOOP
   V_POSICAO := 1;
    BEGIN
    
        FETCH C_DUPLICIDADES INTO R_DUPLICIDADES;
        EXIT WHEN C_DUPLICIDADES%NOTFOUND;
        
        P_IND_ERRO := 0;
        P_MSG_RETORNO := '';
        
        -- VERIFICA A SITUAÇÃO DA DILUIÇÃO [PARCELAS DA DILUIÇÃO]
        -- - TODAS PENDENTES
        -- - ALGUMA(S) APROPRIADA(S)
        -- - ALGUMA(S) QUITADA(S)
        V_POSICAO := 2;
                
        -- SELECIONA AS PARCELAS
        FOR C_SITUACAO_DEBITO IN (
          SELECT SITUACAO, COUNT(SITUACAO) CNT_SITUACAO, SUM(VAL_RECEBIDO) AS VAL_RECEBIDO
          FROM (
          --ALUNO
          SELECT DECODE(DM.IND_SITUACAO_DEBITO,'1','1.PENDENTE','2',DECODE(NVL(CA.IND_SITUACAO_CARNE,'0'),'2','3.QUITADO','1','2.APROPRIADO','1,PENDENTE'),'3','4.CANCELADO','5.DESCONHECIDO') SITUACAO, DM.VAL_RECEBIDO
            FROM SIA.ACORDO_ESPECIAL_TITULOS ACET
               , SIA.DEBITO_MENSALIDADE DM
               , SIA.DEBITO_CREDITO_CONSUMIDO DCC
               , SIA.CARNE CA
           WHERE ACET.NUM_SEQ_DEBITO_MENSALIDADE = DM.NUM_SEQ_DEBITO_MENSALIDADE
              AND DM.NUM_SEQ_DEBITO_MENSALIDADE = DCC.NUM_SEQ_DEBITO_MENSALIDADE (+)
              AND DCC.NUM_SEQ_CARNE = CA.NUM_SEQ_CARNE (+)
              AND ACET.IND_RELACAO = 2 
              AND DM.IND_SITUACAO_DEBITO <> 3 
              AND ACET.NUM_SEQ_ACORDO_ESPECIAL = R_DUPLICIDADES.num_seq_acordo_especial 
              AND EXISTS (SELECT 1
                FROM SIA.DEBITO_MENSALIDADE DM2
               INNER JOIN SIA.ACORDO_ESPECIAL_TITULOS AET2 ON AET2.NUM_SEQ_DEBITO_MENSALIDADE = DM2.NUM_SEQ_DEBITO_MENSALIDADE
                WHERE DM2.NUM_SEQ_ALUNO_CURSO = DM.NUM_SEQ_ALUNO_CURSO
                  AND DM2.COD_MOTIVO_DEBITO = DM.COD_MOTIVO_DEBITO
                  AND DM2.IND_SITUACAO_DEBITO <> '3'
                  AND DM2.DT_MES_ANO_REFERENCIA = DM.DT_MES_ANO_REFERENCIA
                  AND DM2.ROWID < DM.ROWID
                  AND DM2.COD_MOTIVO_DEBITO in (77,78)
                  AND AET2.NUM_SEQ_ACORDO_ESPECIAL = ACET.NUM_SEQ_ACORDO_ESPECIAL
                  )
          UNION ALL
          --CANDIDATO
          SELECT DECODE(DM.IND_SITUACAO_DEBITO,'1','1.PENDENTE','2',DECODE(NVL(CA.IND_SITUACAO_CARNE,'0'),'2','3.QUITADO','1','2.APROPRIADO','1,PENDENTE'),'3','4.CANCELADO','5.DESCONHECIDO') SITUACAO,  DM.VAL_RECEBIDO
            FROM SIA.ACORDO_ESPECIAL_TITULOS ACET
               , SIA.DEBITO_MENSALIDADE DM
               , SIA.DEBITO_CREDITO_CONSUMIDO DCC
               , SIA.CARNE CA
           WHERE ACET.NUM_SEQ_DEBITO_MENSALIDADE = DM.NUM_SEQ_DEBITO_MENSALIDADE
              AND DM.NUM_SEQ_DEBITO_MENSALIDADE = DCC.NUM_SEQ_DEBITO_MENSALIDADE (+)
              AND DCC.NUM_SEQ_CARNE = CA.NUM_SEQ_CARNE (+)
              AND ACET.IND_RELACAO = 2 
              AND DM.IND_SITUACAO_DEBITO <> 3 
              AND ACET.NUM_SEQ_ACORDO_ESPECIAL = R_DUPLICIDADES.NUM_SEQ_ACORDO_ESPECIAL 
              AND EXISTS (SELECT 1
                FROM SIA.DEBITO_MENSALIDADE DM2
               INNER JOIN SIA.ACORDO_ESPECIAL_TITULOS AET2 ON AET2.NUM_SEQ_DEBITO_MENSALIDADE = DM2.NUM_SEQ_DEBITO_MENSALIDADE
                WHERE DM2.NUM_SEQ_CANDIDATO = DM.NUM_SEQ_CANDIDATO
                  AND DM2.COD_MOTIVO_DEBITO = DM.COD_MOTIVO_DEBITO
                  AND DM2.IND_SITUACAO_DEBITO <> '3'
                  AND DM2.DT_MES_ANO_REFERENCIA = DM.DT_MES_ANO_REFERENCIA
                  AND DM2.ROWID < DM.ROWID
                  AND DM2.COD_MOTIVO_DEBITO in (77,78)
                  AND AET2.NUM_SEQ_ACORDO_ESPECIAL = ACET.NUM_SEQ_ACORDO_ESPECIAL
                  )
                    
          )
            GROUP BY SITUACAO
            ORDER BY SITUACAO DESC
          )
          
        LOOP 
           
           SELECT SUM(DM.VAL_A_RECEBER)
                INTO V_VALOR_A_RECEBER  
                FROM SIA.ACORDO_ESPECIAL_TITULOS ACET 
                   , SIA.DEBITO_MENSALIDADE DM 
                   , SIA.DEBITO_CREDITO_CONSUMIDO DCC                 
                   , SIA.CARNE CA                                           
               WHERE ACET.NUM_SEQ_DEBITO_MENSALIDADE = DM.NUM_SEQ_DEBITO_MENSALIDADE 
                 AND DM.NUM_SEQ_DEBITO_MENSALIDADE = DCC.NUM_SEQ_DEBITO_MENSALIDADE (+)  
                 AND DCC.NUM_SEQ_CARNE = CA.NUM_SEQ_CARNE (+)                                   
                 AND ACET.IND_RELACAO = 2 
                 AND DM.IND_SITUACAO_DEBITO <> 3 
                 AND ACET.NUM_SEQ_ACORDO_ESPECIAL = R_DUPLICIDADES.NUM_SEQ_ACORDO_ESPECIAL  
               ORDER BY DM.DT_MES_ANO_REFERENCIA;
               
               --DBMS_OUTPUT.PUT_LINE(' V_VALOR_A_RECEBER: ' ||  V_VALOR_A_RECEBER);
        
            -- QUITADOS
             DBMS_OUTPUT.PUT_LINE(' C_SITUACAO_DEBITO.SITUACAO: ' ||  C_SITUACAO_DEBITO.SITUACAO);
             DBMS_OUTPUT.PUT_LINE(' C_SITUACAO_DEBITO.CNT_SITUACAO: ' ||  C_SITUACAO_DEBITO.CNT_SITUACAO);
             
            IF (C_SITUACAO_DEBITO.SITUACAO = '3.QUITADO') AND C_SITUACAO_DEBITO.CNT_SITUACAO > 0 THEN
             V_POSICAO := 3;
            
             -- GERA O(S) CRÉDITO(S) DE ACORDO COM A(S) PARCELA(S) DE DILUIÇÃO QUE ESTÁ(ÃO) QUITADA(S)
              
              DBMS_OUTPUT.PUT_LINE(' ---- 3.QUITADO ');
              DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.COD_MATRICULA: ' ||  R_DUPLICIDADES.COD_MATRICULA);
              DBMS_OUTPUT.PUT_LINE(' C_SITUACAO_DEBITO.VAL_RECEBIDO: ' ||  C_SITUACAO_DEBITO.VAL_RECEBIDO);
              DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.VAL_A_PAGAR_ORIG: ' ||  R_DUPLICIDADES.VAL_A_PAGAR_ORIG);
              DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO: ' ||  R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO);
              DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.NUM_SEQ_CANDIDATO: ' ||  R_DUPLICIDADES.NUM_SEQ_CANDIDATO);
              DBMS_OUTPUT.PUT_LINE(' ---------  ');
             
              
              --IF C_SITUACAO_DEBITO.VAL_RECEBIDO < R_DUPLICIDADES.VAL_A_PAGAR_ORIG THEN            
                 V_POSICAO := 4;
                 INSERT INTO SIA.CREDITO_MENSALIDADE
                     (COD_MOEDA, COD_MOTIVO_CREDITO, TXT_CREDITO_MENSALIDADE, VAL_RESTITUIDO, 
                     IND_SITUACAO_CREDITO, DT_MES_ANO_REFERENCIA, IND_TIPO_CREDITO, 
                     NUM_SEQ_ALUNO_CURSO, NUM_SEQ_CANDIDATO, VAL_RESTITUICAO, NUM_SEQ_CREDITO_MENSALIDADE)
                 VALUES(
                     R_DUPLICIDADES.COD_MOEDA, 19, 'DEVOLUÇÃO POR PAGAMENTO DE PARCELAS DO DIS EFETUADO EM DUPLICIDADE',
                     0, 1, R_DUPLICIDADES.DT_INI_PERIODO,
                     1, R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO, R_DUPLICIDADES.NUM_SEQ_CANDIDATO, C_SITUACAO_DEBITO.VAL_RECEBIDO,
                     SIA.S_CREDITO_MENSALIDADE.NEXTVAL
                     );
              /*ELSE
                  V_POSICAO := 4;
                  INSERT INTO SIA.CREDITO_MENSALIDADE
                     (COD_MOEDA, COD_MOTIVO_CREDITO, TXT_CREDITO_MENSALIDADE, VAL_RESTITUIDO, 
                     IND_SITUACAO_CREDITO, DT_MES_ANO_REFERENCIA, IND_TIPO_CREDITO, 
                     NUM_SEQ_ALUNO_CURSO, NUM_SEQ_CANDIDATO, VAL_RESTITUICAO, NUM_SEQ_CREDITO_MENSALIDADE)
                  VALUES(
                     R_DUPLICIDADES.COD_MOEDA, 19, 'DEVOLUÇÃO POR PAGAMENTO DE PARCELAS DO DIS EFETUADO EM DUPLICIDADE',
                     0, 1, R_DUPLICIDADES.DT_INI_PERIODO,
                     1, R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO, R_DUPLICIDADES.NUM_SEQ_CANDIDATO, C_SITUACAO_DEBITO.SALDO,
                     SIA.S_CREDITO_MENSALIDADE.NEXTVAL
                     );*/
              --END IF;
            
            ELSIF (C_SITUACAO_DEBITO.SITUACAO = '2.APROPRIADO') AND C_SITUACAO_DEBITO.CNT_SITUACAO > 0 THEN
               
               
                 /*dbms_output.put_line(' [APROP.] CANCELA_CARNES_SUPERIORES: ' || V_NSEQ_ACORDO_ESPECIAL); */
                -- 1 -PENDENTES / APROPRIADAS
                -- PARA O CASO DE TODAS AS PARCELAS ESTAREM PENDENTES OU APROPRIADAS
                --  * DESVINCULAR A DILUIÇÃO
                --  * CANCELAR O CARNÊ
                --  * CANCELAR OS DÉBITOS
                 
                DBMS_OUTPUT.PUT_LINE(' ---- 2.APROPRIADO');
                DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.COD_MATRICULA: ' ||  R_DUPLICIDADES.COD_MATRICULA);
                DBMS_OUTPUT.PUT_LINE(' C_SITUACAO_DEBITO.VAL_RECEBIDO: ' ||  C_SITUACAO_DEBITO.VAL_RECEBIDO);
                DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.VAL_A_PAGAR_ORIG: ' ||  R_DUPLICIDADES.VAL_A_PAGAR_ORIG);
                DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO: ' ||  R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO);
                DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.NUM_SEQ_CANDIDATO: ' ||  R_DUPLICIDADES.NUM_SEQ_CANDIDATO);
                DBMS_OUTPUT.PUT_LINE(' ---------  ');
                
                -- CANCELA TODAS AS PARCLAS PENDENTES APÓS O CANCELAMENTO DOS CARNÊS QUE ELAS ESTAVAM APROPRIADAS.
                    V_POSICAO := 5; 
                     
                     UPDATE SIA.DEBITO_MENSALIDADE DM
                     SET DM.IND_SITUACAO_DEBITO = '3'
                     WHERE DM.NUM_SEQ_DEBITO_MENSALIDADE IN (
                           SELECT DM.NUM_SEQ_DEBITO_MENSALIDADE
                               FROM SIA.ACORDO_ESPECIAL ACO
                              INNER JOIN SIA.ACORDO_ESPECIAL_TITULOS AET
                                 ON AET.NUM_SEQ_ACORDO_ESPECIAL = ACO.NUM_SEQ_ACORDO_ESPECIAL
                              INNER JOIN SIA.DEBITO_MENSALIDADE DM
                                 ON DM.NUM_SEQ_DEBITO_MENSALIDADE = AET.NUM_SEQ_DEBITO_MENSALIDADE
                              WHERE ACO.NUM_SEQ_ACORDO_ESPECIAL = R_DUPLICIDADES.NUM_SEQ_ACORDO_ESPECIAL
                                AND AET.IND_RELACAO = 2
                                AND DM.IND_SITUACAO_DEBITO = '1'
                                AND EXISTS (SELECT 1
                                             FROM SIA.DEBITO_MENSALIDADE DM2
                                            INNER JOIN SIA.ACORDO_ESPECIAL_TITULOS AET2
                                               ON AET2.NUM_SEQ_DEBITO_MENSALIDADE = DM2.NUM_SEQ_DEBITO_MENSALIDADE
                                            WHERE (DM2.NUM_SEQ_ALUNO_CURSO = DM.NUM_SEQ_ALUNO_CURSO OR DM2.NUM_SEQ_CANDIDATO = DM.NUM_SEQ_CANDIDATO)
                                              AND DM2.COD_MOTIVO_DEBITO = DM.COD_MOTIVO_DEBITO
                                              AND DM2.IND_SITUACAO_DEBITO <> '3'
                                              AND DM2.DT_MES_ANO_REFERENCIA = DM.DT_MES_ANO_REFERENCIA
                                              AND DM2.IND_SITUACAO_DEBITO = DM.IND_SITUACAO_DEBITO
                                              AND DM2.ROWID < DM.ROWID
                                              AND DM2.COD_MOTIVO_DEBITO in (77,78) -- (DILUIÇÃO SOLIDÁRIA - DIS, ANTECIPAÇÃO PARCELAS DILUIÇÃO - DIS)
                                              AND AET2.NUM_SEQ_ACORDO_ESPECIAL = ACO.NUM_SEQ_ACORDO_ESPECIAL
                                            )
                               );
                 
                      
                 -- VARRE TODOS OS CARNÊS DE MENSALIDADE SUPERIORES PARA O CANCELAMENTO DOS MESMOS
                 FOR CARNES_MENSALIDADE IN (SELECT CAR.NUM_SEQ_CARNE, CAR.DT_VENCIMENTO, CAR.DT_MES_ANO_COMPETENCIA, CAR.TXT_NOSSO_NUMERO, CAR.IND_SITUACAO_CARNE
                                        FROM SIA.CARNE CAR
                                       WHERE (CAR.NUM_SEQ_ALUNO_CURSO = R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO OR CAR.NUM_SEQ_CANDIDATO = R_DUPLICIDADES.NUM_SEQ_CANDIDATO )
                                         AND CAR.DT_MES_ANO_COMPETENCIA >= R_DUPLICIDADES.DT_MES_ANO_COMPETENCIA
                                         AND CAR.IND_TIPO_CARNE IN (3,6) --SOMENTE ESSES POIS O DIS É PARA INGRESSANTES E REABERTURAS.
                                         AND CAR.IND_SITUACAO_CARNE = 1  --PENDENTE
                                    ORDER BY CAR.DT_MES_ANO_COMPETENCIA DESC)
                    
                 LOOP
                    
                    -- REALIZA O CANCELAMENTO DO CARNÊ DE MENSALIDADE
                    SIA.FIN_CANCELA_CARNE(CARNES_MENSALIDADE.NUM_SEQ_CARNE
                                           ,P_IND_ERRO
                                           ,P_MSG_RETORNO
                                           ,NULL -- P_NUM_SEQ_ALUNO_TURMA_EXT_NOVO
                                           ,NULL -- V_NSEQ_ALUNO_CURSO
                                           ,NULL -- V_NSEQ_ALUNO_TURMA_EXTENSAO
                                           ,NULL -- V_NSEQ_CANDIDATO
                                           ,NULL -- V_DT_MES_ANO_COMPETENCIA
                                           ,NULL
                                           ,'N' -- COMMIT
                                           );
                    IF P_IND_ERRO <> 0 THEN
                          INSERT INTO SIA.DIS_CENARIO_LOG (NUM_SEQ_CENARIO, NUM_SEQ_ALUNO_CURSO, NUM_SEQ_CANDIDATO, NUM_SEQ_PERIODO_ACADEMICO, DT_MES_ANO_COMPETENCIA, TXT_MSG_ERRO, DT_LOG)
                                                   VALUES (V_NUM_SEQ_CENARIO_EXECUCAO, R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO, R_DUPLICIDADES.NUM_SEQ_CANDIDATO, NULL, R_DUPLICIDADES.DT_MES_ANO_COMPETENCIA, 'SIA.FIN_CANCELA_CARNE -- ' || P_MSG_RETORNO, SYSDATE);
                          P_IND_ERRO := 0;
                          P_MSG_RETORNO := 0;
                    ELSE
                        T_CARNE_REGERAR.EXTEND();
                        --T_CARNE_REGERAR(T_CARNE_REGERAR.COUNT).NUM_SEQ_ALUNO_CURSO     := V_NSEQ_ALUNO_CURSO_REG;
                        --T_CARNE_REGERAR(T_CARNE_REGERAR.COUNT).NUM_SEQ_CANDIDATO       := V_NSEQ_CANDIDATO_REG;
                        T_CARNE_REGERAR(T_CARNE_REGERAR.COUNT).DT_VENCIMENTO           := CARNES_MENSALIDADE.DT_VENCIMENTO;
                        --T_CARNE_REGERAR(T_CARNE_REGERAR.COUNT).IND_TIPO_CARNE          := CARNES_MENSALIDADE.IND_TIPO_CARNE;
                        T_CARNE_REGERAR(T_CARNE_REGERAR.COUNT).DT_MES_ANO_COMPETENCIA  := CARNES_MENSALIDADE.DT_MES_ANO_COMPETENCIA;
                    END IF;                
                    dbms_output.put_line(' [APROP.] CARNÊ MENSALIDADE - CARNES_MENSALIDADE.NUM_SEQ_CARNE: ' || CARNES_MENSALIDADE.NUM_SEQ_CARNE); 
                    --dbms_output.put_line(' [APROP.] CARNÊ MENSALIDADE - V_IND_ERRO: ' || P_IND_ERRO); 
                    --dbms_output.put_line(' [APROP.] CARNÊ MENSALIDADE - V_MSG_RETORNO: ' || P_MSG_RETORNO); 
                    --dbms_output.put_line(' V_MIN_DEB_PEND: ' || V_MIN_DEB_PEND); 
                 END LOOP;
                 FOR I IN REVERSE 1..T_CARNE_REGERAR.COUNT LOOP
                        
                        SIA.FIN_CICLO.GET_INSTITUICAO(R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO
                                                     ,R_DUPLICIDADES.NUM_SEQ_CANDIDATO
                                                     ,NULL
                                                     ,V_COD_INSTITUICAO);
                        
                        DBMS_OUTPUT.PUT_LINE('ANTES DE GERAR O CARNÊ - C_SITUACAO_DEBITO.SITUACAO = 2.APROPRIADO' );
                        DBMS_OUTPUT.PUT_LINE(' ---------------------------------------------------------------- ' );
                        DBMS_OUTPUT.PUT_LINE('** ADICIONANDO CARNE - T_CARNE_REGERAR(I).DT_MES_ANO_COMPETENCIA: ' || T_CARNE_REGERAR(I).DT_MES_ANO_COMPETENCIA);
                        DBMS_OUTPUT.PUT_LINE('** ADICIONANDO CARNE - T_CARNE_REGERAR(I).DT_VENCIMENTO: ' || T_CARNE_REGERAR(I).DT_VENCIMENTO);
                        DBMS_OUTPUT.PUT_LINE('** ADICIONANDO CARNE - V_COD_INSTITUICAO: ' || V_COD_INSTITUICAO);
                        DBMS_OUTPUT.PUT_LINE('** T_CARNE_REGERAR(I): ' || T_CARNE_REGERAR.COUNT);
                        DBMS_OUTPUT.PUT_LINE('                                                                       ' );
                        DBMS_OUTPUT.PUT_LINE('                                                                       ' );
                        
                        SIA.FIN_CICLO.CALCULAR(P_MSG_RETORNO           => P_MSG_RETORNO,
                                           P_IND_ERRO                  => P_IND_ERRO,
                                           P_NSEQ_CICLO                => NULL,
                                           P_SGL_MANTENEDORA           => NULL,
                                           P_COD_INSTITUICAO           => V_COD_INSTITUICAO,
                                           P_NSEQ_SELECAO              => NULL,
                                           P_DT_COMPETENCIA            => T_CARNE_REGERAR(I).DT_MES_ANO_COMPETENCIA,
                                           P_NSEQ_SACADO               => NULL,
                                           P_NSEQ_ALUNO_CURSO          => R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO,
                                           P_NSEQ_ALUNO_TURMA_EXTENSAO => NULL,
                                           P_NSEQ_CANDIDATO            => NULL,
                                           P_DT_VENCIMENTO             => T_CARNE_REGERAR(I).DT_VENCIMENTO,
                                           P_IND_AVULSO                => 'S',
                                           P_IND_REABERTURA            => NULL,
                                           P_COMMIT                    => 'N');
                        IF P_IND_ERRO <> '0' THEN
                           INSERT INTO SIA.DIS_CENARIO_LOG (NUM_SEQ_CENARIO, NUM_SEQ_ALUNO_CURSO, NUM_SEQ_CANDIDATO, NUM_SEQ_PERIODO_ACADEMICO, DT_MES_ANO_COMPETENCIA, TXT_MSG_ERRO, DT_LOG)
                                                           VALUES (V_NUM_SEQ_CENARIO_EXECUCAO, R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO, R_DUPLICIDADES.NUM_SEQ_CANDIDATO, NULL, R_DUPLICIDADES.DT_MES_ANO_COMPETENCIA, 'SIA.FIN_CICLO.CALCULAR -- ' || P_MSG_RETORNO, SYSDATE);
                           P_IND_ERRO := 0;
                           P_MSG_RETORNO := 0;
                         ELSE
                           DBMS_OUTPUT.PUT_LINE(' CALCULEI  C_SITUACAO_DEBITO.SITUACAO = 2.APROPRIADO ' );
                           DBMS_OUTPUT.PUT_LINE(' ---------------------------------------------------------------- ' );
                           DBMS_OUTPUT.PUT_LINE(' P_MSG_RETORNO: ' ||  P_MSG_RETORNO);
                           DBMS_OUTPUT.PUT_LINE(' V_COD_INSTITUICAO: ' || V_COD_INSTITUICAO);
                           DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.DT_MES_ANO_COMPETENCIA_POS: ' ||  R_DUPLICIDADES.DT_MES_ANO_COMPETENCIA);
                           DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO: ' ||  R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO);
                           DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.DT_VENCIMENTO: ' ||  R_DUPLICIDADES.DT_VENCIMENTO); 
                           DBMS_OUTPUT.PUT_LINE('                                                                       ' );
                           DBMS_OUTPUT.PUT_LINE('                                                                       ' );      
                        END IF;
                    END LOOP; 
                 
                               
                     -- GERA CARNÊ PARA OS ALUNOS INATIVOS ATRAVÉS DA ANTECIPAÇÃO DE DÉBITOS DO DIS
                     IF R_DUPLICIDADES.COD_SITUACAO_ALUNO = 3 THEN
                        
                        DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.COD_SITUACAO_ALUNO: ' || R_DUPLICIDADES.COD_SITUACAO_ALUNO);
                       -- DBMS_OUTPUT.PUT_LINE(' CARNES_MENSALIDADE.NUM_SEQ_CARNE: ' || CARNES_MENSALIDADE.NUM_SEQ_CARNE);
                        DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO: ' ||  R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO);
                        DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.NUM_SEQ_CANDIDATO: ' ||  R_DUPLICIDADES.NUM_SEQ_CANDIDATO);
                         
                        V_POSICAO := 6;
                        SIA.PKG_FIN_FAT_DILUICAO.GERAR_CARNE_DILUICAO(P_IND_ERRO
                                                                     ,P_MSG_RETORNO
                                                                     ,R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO
                                                                     ,R_DUPLICIDADES.NUM_SEQ_CANDIDATO
                                                                     );
                         IF P_IND_ERRO <> 0 THEN
                              INSERT INTO SIA.DIS_CENARIO_LOG (NUM_SEQ_CENARIO, NUM_SEQ_ALUNO_CURSO, NUM_SEQ_CANDIDATO, NUM_SEQ_PERIODO_ACADEMICO, DT_MES_ANO_COMPETENCIA, TXT_MSG_ERRO, DT_LOG)
                                                       VALUES (V_NUM_SEQ_CENARIO_EXECUCAO, R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO, R_DUPLICIDADES.NUM_SEQ_CANDIDATO, NULL, R_DUPLICIDADES.DT_MES_ANO_COMPETENCIA, 'SIA.PKG_FIN_FAT_DILUICAO.GERAR_CARNE_DILUICAO -- ' || P_MSG_RETORNO, SYSDATE);
                              P_IND_ERRO := '0';
                              P_MSG_RETORNO := '0';
                         END IF;
                         V_POSICAO := 7;  
                     END IF;       
            ELSE
            V_POSICAO := 8;
            -- ALTERA O STATUS DA PARCELA PENDENTE PRESERVANDO A PARCELA MAIS ANTIGA
                IF (C_SITUACAO_DEBITO.SITUACAO = '1.PENDENTE') AND C_SITUACAO_DEBITO.CNT_SITUACAO > 0 THEN
                  
                     V_POSICAO := 9; 
                    
                  DBMS_OUTPUT.PUT_LINE(' ---- 1.PENDENTE');
                  DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.COD_MATRICULA: ' ||  R_DUPLICIDADES.COD_MATRICULA);
                  DBMS_OUTPUT.PUT_LINE(' C_SITUACAO_DEBITO.VAL_RECEBIDO: ' ||  C_SITUACAO_DEBITO.VAL_RECEBIDO);
                  DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.VAL_A_PAGAR_ORIG: ' ||  R_DUPLICIDADES.VAL_A_PAGAR_ORIG);
                  DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO: ' ||  R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO);
                  DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.NUM_SEQ_CANDIDATO: ' ||  R_DUPLICIDADES.NUM_SEQ_CANDIDATO);
                  DBMS_OUTPUT.PUT_LINE(' ---------  ');
                  
                     
                     V_POSICAO := 10; 
                  
                   IF R_DUPLICIDADES.VAL_A_PAGAR_ORIG <> V_VALOR_A_RECEBER THEN
                              
                     UPDATE SIA.DEBITO_MENSALIDADE DM
                     SET DM.IND_SITUACAO_DEBITO = '3'
                     WHERE DM.NUM_SEQ_DEBITO_MENSALIDADE IN (
                           SELECT DM.NUM_SEQ_DEBITO_MENSALIDADE
                               FROM SIA.ACORDO_ESPECIAL ACO
                              INNER JOIN SIA.ACORDO_ESPECIAL_TITULOS AET
                                 ON AET.NUM_SEQ_ACORDO_ESPECIAL = ACO.NUM_SEQ_ACORDO_ESPECIAL
                              INNER JOIN SIA.DEBITO_MENSALIDADE DM
                                 ON DM.NUM_SEQ_DEBITO_MENSALIDADE = AET.NUM_SEQ_DEBITO_MENSALIDADE
                              WHERE ACO.NUM_SEQ_ACORDO_ESPECIAL = R_DUPLICIDADES.num_seq_acordo_especial
                                AND AET.IND_RELACAO = 2
                                AND DM.IND_SITUACAO_DEBITO = '1'
                                AND EXISTS (SELECT 1
                                             FROM SIA.DEBITO_MENSALIDADE DM2
                                            INNER JOIN SIA.ACORDO_ESPECIAL_TITULOS AET2
                                               ON AET2.NUM_SEQ_DEBITO_MENSALIDADE = DM2.NUM_SEQ_DEBITO_MENSALIDADE
                                            WHERE (DM2.NUM_SEQ_ALUNO_CURSO = DM.NUM_SEQ_ALUNO_CURSO OR DM2.NUM_SEQ_CANDIDATO = DM.NUM_SEQ_CANDIDATO)
                                              AND DM2.COD_MOTIVO_DEBITO = DM.COD_MOTIVO_DEBITO
                                              AND DM2.IND_SITUACAO_DEBITO <> '3'
                                              AND DM2.DT_MES_ANO_REFERENCIA = DM.DT_MES_ANO_REFERENCIA
                                              AND DM2.IND_SITUACAO_DEBITO = DM.IND_SITUACAO_DEBITO
                                              AND DM2.ROWID < DM.ROWID
                                              AND DM2.COD_MOTIVO_DEBITO in (77,78)
                                              AND AET2.NUM_SEQ_ACORDO_ESPECIAL = ACO.NUM_SEQ_ACORDO_ESPECIAL
                                            )
                               );
                     END IF;            
                      V_POSICAO := 11;         
                  ELSE
                  V_POSICAO := 12;
                     EXIT;
                END IF;
                V_POSICAO := 13;
                
            END IF;
        END LOOP;
        V_POSICAO := 14;  
 
        --- V_SEQ
        IF V_SEQ >= 10 THEN
           V_SEQ := 0;
        END IF;
        V_SEQ := V_SEQ + 1;
        ---

        IF V_ALUNO_ATUAL = 0 THEN
           select SYSDATE INTO V_DATE FROM DUAL;
        ELSE
            select sysdate + (V_SEQ/24/60/60) INTO V_DATE from dual;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE(' ---- ANTES DO INSERT');
        DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.NUM_SEQ_ALUNO: ' ||  R_DUPLICIDADES.NUM_SEQ_ALUNO);
        DBMS_OUTPUT.PUT_LINE(' DT_OCORRENCIA: ' || to_char(v_date, 'dd/mm/yyyy hh:mi:ss'));
        DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO: ' ||  R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO);
        DBMS_OUTPUT.PUT_LINE(' V_ALUNO_ATUAL: ' ||  V_ALUNO_ATUAL);
        
        INSERT INTO SIA.OCORRENCIAS_ALUNO ( NUM_SEQ_ALUNO, 
                                            DT_OCORRENCIA, 
                                            COD_TIPO_OCORRENCIA, 
                                            NUM_SEQ_ALUNO_CURSO,    
                                            TXT_OCORRENCIA) 
                                   VALUES ( R_DUPLICIDADES.NUM_SEQ_ALUNO,
                                             V_DATE, 
                                             14,
                                             R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO ,
                                             'CR45 - DIS - CORREÇÃO DAS PARCELAS DUPLICADAS GERANDO CRÉDITO PARA O ALUNO - ACORDO ESPECIAL = ' || R_DUPLICIDADES.num_seq_acordo_especial);
                                                 
         V_ALUNO_ATUAL := R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO;                                              
         DBMS_OUTPUT.PUT_LINE(' ---- DEPOIS DO INSERT');
         DBMS_OUTPUT.PUT_LINE(' R_DUPLICIDADES.COD_MATRICULA: ' ||  R_DUPLICIDADES.COD_MATRICULA);
         DBMS_OUTPUT.PUT_LINE(' DT_OCORRENCIA DEPOIS: ' || to_char(v_date, 'dd/mm/yyyy hh:mi:ss'));
         DBMS_OUTPUT.PUT_LINE(' V_ALUNO_ATUAL: ' ||  V_ALUNO_ATUAL);
         DBMS_OUTPUT.PUT_LINE(' -------------------');

        V_POSICAO := 15;
   EXCEPTION
      WHEN OTHERS THEN
           ROLLBACK;
           DBMS_OUTPUT.PUT_LINE('ROLLBACK REALIZADO. OCORREU ERRO - INT:' || SQLERRM ||  ' V_POSICAO = ' || V_POSICAO);
           P_MSG_RETORNO := SQLERRM;
           
           INSERT INTO SIA.DIS_CENARIO_LOG (NUM_SEQ_CENARIO, NUM_SEQ_ALUNO_CURSO, NUM_SEQ_CANDIDATO, NUM_SEQ_PERIODO_ACADEMICO, DT_MES_ANO_COMPETENCIA, TXT_MSG_ERRO, DT_LOG)
                                 VALUES (V_NUM_SEQ_CENARIO_EXECUCAO, R_DUPLICIDADES.NUM_SEQ_ALUNO_CURSO, R_DUPLICIDADES.NUM_SEQ_CANDIDATO, NULL, R_DUPLICIDADES.DT_MES_ANO_COMPETENCIA, P_MSG_RETORNO, SYSDATE);
           NULL;
      END;
      V_POSICAO := 16;
  END LOOP;
  COMMIT;
     
  DBMS_OUTPUT.PUT_LINE('OPERAÇÃO EXECUTADA COM SUCESSO!');     
  CLOSE C_DUPLICIDADES;
EXCEPTION
  WHEN OTHERS THEN
       ROLLBACK;
       DBMS_OUTPUT.PUT_LINE('ROLLBACK REALIZADO. OCORREU ERRO - EXT:' || SQLERRM ||  ' V_POSICAO = ' || V_POSICAO);
END;
