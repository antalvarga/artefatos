create or replace procedure sia.ProcTratativaPRB45
/* TO DO
   *** Lembrete *** 
  
  . Verificar porque o num_seq_acordo_especial = 3125 está retornando mais de uma linha causando erro
  . ****  RETIRAR   os comentários do insert e update  **** ---

  . Exemplos para testes
    . Acordo com Carne negociado :             
                                     NUM_SEQ_ACORDO_ESPECIAL
                                      1094035

                                      
    . Acordo com credito 113 :
                                      NUM_SEQ_ACORDO_ESPECIAL
                                      , '1095030'
                                      , '1092853'
                                      , '1095057'
                                     
        
    . Acordo com Credito 19 mensagem 1 :
                                       NUM_SEQ_ACORDO_ESPECIAL
                                        , '1090603'
                                        , '1089457'
                                        , '578250'
                                        , '1090094'
                                        , '1096917'
                                        , '1097659'
                                        , '1088761'
                                        , '1090602'
                                        , '1091976'
                                        , '1090212'
                                        , '1095057'
 
    
    . Acordo com Credito 19 mensagem 2 :                                                                          
                                        NUM_SEQ_ACORDO_ESPECIAL
                                        , '1090603'
                                        , '1092913'
                                        , '1091591'
                                        , '578250'
                                        , '1096973'
                                        , '1088000'
                                        , '1090094'
                                        , '1090792'
                                        , '1096917'
                                        , '1099573'
                                        , '1096191'
                                        , '1094927'
                                        , '1099006'
                                        , '1088761'
                                        , '1090602'
                                        , '1098483'
                                        , '1091976'
                                        , '1094971'
                                        , '1095057'





--- *** Estatísticas ***
---. Temos um total de 1.082.788 acordo CONFIRMADO especial DIS ATUAL 
---. No dia 20200409 a data máxima (último dia )   20200404
---. No dia 20200409 a data mínima (primeiro dia ) 20180125
  
*/
is
  -- Variaveis, arrays, cursores, functions
  MyPoint number;
  MyAcordo number;
  MyReturn number;
  MyFormado number;
  MyCredito19 number;
  MyMatricula number;
  --  MyCredito113 number;
  MyIpLog varchar2(100);

  MyParam varchar2(500);
  ErrOracle varchar2(3700);
  
  MyError varchar2(500);
  MyIndErro number;
  MyCarne number;
  -- AV 20200423
  MyTxtNossoNumero varchar2(50);
  MyCandidato number;
  MyCarneValor numeric(15,2);
  
  My_1_TextoCredito19 varchar2(100);
  My_2_TextoCredito19 varchar2(100);
  
  -- Totalizadores  
  MySum number;
  MyCount number;
  MyIndex integer;

  type MyArray is varray( 10 ) of varchar2(50);
  MyDescription MyArray := MyArray(  'ALUNOS FORMADOS'
                                   , 'CREDITO 19 PARA ACERTO DE PAGAMENTO A MAIOR'
                                   , 'CANCELAR DEBITOS PENDENTES'
                                   , 'INSERIR CREDITO MENSAL.CONSUMIDO VALOR<>NULL'
                                   , 'SITUACAO CARNE PENDENTE'
                                   , 'GERAR CREDITO, CASO NAO CONSIGA CANCELAR O CARNE'
                                   , 'Enviar para analise'
                                   , 'TOTAL DE LINHAS ANALISADAS'
                                 );       
                
  type MyRecord is record ( Id number
                            , Description varchar2(50)
                            , Summary number
                           );
                             
  type MyTable is table of MyRecord index by binary_integer;
  
  MySummary MyTable;

  /*
  
    Consulta atualizada pelo 
    e-mail Marcia Nepomuceno do Amaral <marcia.amaral.ter@estacio.br>
    em sexta-feira, 7 de fevereiro de 2020 16:58
    Para Antal Varga  

    0 - Listar Para cada acordo especial DIS ATUAL confirmado 
      E valor carne menos (-) somatório dos debitos mensalidades 
      ( com situação diferente de cancelado ) for menor que zero      
  */
  cursor cursorAcordo is
     select ae.num_seq_acordo_especial 
       , ae.cod_tipo_acordo_especial
       , tp.nom_tipo_acordo_especial 
       , ae.num_seq_aluno_curso
       , 
       -- Incluir o num_seq_carne para utilizar a fin_cancela_carne
       -- Validar com a Marcia ***
       ( select aet.num_seq_carne  
         from sia.acordo_especial_titulos aet 
         -- ind_relacao = 0 carne que originou 
         where aet.ind_relacao = 0
         and   aet.num_seq_acordo_especial = ae.num_seq_acordo_especial 
       ) num_seq_carne
       --- *** 
       ,           
       (select car.val_a_pagar  
       from sia.carne car , 
            sia.acordo_especial_titulos aet 
      -- ind_relacao = 0 carne que originou 
       where aet.ind_relacao = 0
       and   aet.num_seq_acordo_especial = ae.num_seq_acordo_especial 
       and   aet.num_seq_carne = car.num_seq_carne 
       ) valor_divida_antiga 
       ,
      (select sum( dm.val_a_receber ) 
       from sia.acordo_especial_titulos aet, 
            sia.debito_mensalidade dm 
       -- debitos a serem cobrados do aluno ind_relacao = 2
       where aet.ind_relacao = 2
       and   aet.num_seq_debito_mensalidade = dm.num_seq_debito_mensalidade 
       and   aet.num_seq_acordo_especial = ae.num_seq_acordo_especial
       and   dm.ind_situacao_debito <> '3' 
       )  valor_divida_nova
       , ae.dt_acordo_especial 
       , ae.num_seq_candidato 
       , 
        (select sitc.nom_situacao_candidato 
        from sia.candidato cand, 
             sia.situacao_candidato sitc
        where cand.cod_situacao_candidato = sitc.cod_situacao_candidato 
        and   cand.num_seq_candidato = ae.num_seq_candidato 
        ) situacao_candidato
        ,      
       (select ac.cod_matricula 
        from sia.aluno_curso ac
        where ac.num_seq_aluno_curso = ae.num_seq_aluno_curso
        ) cod_matricula 
        , 
        (select sit.nom_situacao_aluno  
        from sia.aluno_curso ac, 
             sia.situacao_aluno_curso sit 
        where ac.num_seq_aluno_curso = ae.num_seq_aluno_curso
        and   ac.cod_situacao_aluno = sit.cod_situacao_aluno 
        ) situacao_aluno
        ,            
       (select sum(cm.val_restituicao) --- cm.num_seq_credito_mensalidade 
        from sia.credito_mensalidade cm 
        where cm.num_seq_candidato  = ae.num_seq_candidato
        and   cm.txt_credito_mensalidade = 'DEVOLUÇÃO POR PAGAMENTO DE PARCELA CANCELADA DO DIS COBRADA DE FORMA RETROATIVA'
        and   cm.cod_motivo_credito = '19'
        and   cm.ind_situacao_credito in ('1','2') 
       ) valor_tot_cred_candidato 
       ,            
       (select sum(cm.val_restituicao) --- cm.num_seq_credito_mensalidade 
       from sia.credito_mensalidade cm 
       where cm.num_seq_aluno_curso = ae.num_seq_aluno_curso 
       and   cm.txt_credito_mensalidade = 'DEVOLUÇÃO POR PAGAMENTO DE PARCELA CANCELADA DO DIS COBRADA DE FORMA RETROATIVA'
       and   cm.cod_motivo_credito = '19'
       and   cm.ind_situacao_credito in ('1','2') 
       ) valor_tot_cred_aluno           
       -- AV - 20200210 : Atualizado conforme e-mail 
       -- Marcia Nepomuceno do Amaral <marcia.amaral.ter@estacio.br>
       -- Em sex 07/02/2020 16:58
       /*
          3.1 INCLUSÃO DE NOVA COLUNA, COM O TOTAL DE CREDITOS MENSALIDADE MANUAIS DO ALUNO 
          COM IND_SITUACAO_CREDITO IN (1,2) AND COD_MOTIVO_CREDITO = 113 . 
          NÃO UTILIZAR O CAMPO TXT_CREDITO_MENSALIDADE NESSA CONSULTA.
       */
       ,  
       (select sum(cm.val_restituicao) 
       from sia.credito_mensalidade cm 
       where cm.num_seq_aluno_curso = ae.num_seq_aluno_curso 
       and   cm.cod_motivo_credito in( '113' )
       and   cm.ind_situacao_credito in ('1','2') 
       ) tot_cred_manual_113_aluno
       /*
       3.2 INCLUSÃO DE NOVA COLUNA, COM O TOTAL DE CREDITO MENSALIDADE MANUAIS DO CANDIDATO 
       COM IND_SITUACAO_CREDITO IN (1,2) AND COD_MOTIVO_CREDITO = 113 . 
       NÃO UTILIZAR O CAMPO TXT_CREDITO_MENSALIDADE NESSA CONSULTA.
       */
       ,  
       ( select sum(cm.val_restituicao)  
         from sia.credito_mensalidade cm 
         where cm.num_seq_candidato = ae.num_seq_candidato
         and   cm.cod_motivo_credito in( '113' )
         and   cm.ind_situacao_credito in ('1','2') 
        ) tot_cred_manual_113_candidato
       /*
       3.3 ¿ NOVA COLUNA TESTANDO A EXISTENCIA DO  TIPO DE BOLSA'22624' NO CARNE DA DÍVIDA ANTIGA. 
       `ISENÇÃO DE MATRÍCULA - PARCEIRO ONLINE¿
       */
       ,
        (   
          select decode( count(1), 0, 'NAO', 'SIM' )
          from   sia.acordo_especial_titulos aet,
                 sia.mensalidade men, 
                 sia.composicao_mensalidade cm1, 
                 sia.bolsista bol                     
          where  aet.ind_relacao = 0
          and    aet.num_seq_acordo_especial = ae.num_seq_acordo_especial
          and    men.num_seq_carne = aet.num_seq_carne
          and    men.num_seq_mensalidade = cm1.num_seq_mensalidade      
          and    cm1.num_seq_bolsista = bol.num_seq_bolsista 
          and    cm1.cod_tipo_bolsa = '22624'
          --and    rownum = 1               
        ) EXISTE_BOLSA_22624 
       /*
       3.4 - INCLUSÃO DE NOVA COLUNA, COM O TOTAL DE CREDITOS MENSALIDADE MANUAIS 
       DO ALUNO COM IND_SITUACAO_CREDITO IN (1,2) AND COD_MOTIVO_CREDITO = 70 . 
       NÃO UTILIZAR O CAMPO TXT_CREDITO_MENSALIDADE NESSA CONSULTA.
       `DEVOLUÇÃO POR DESISTÊNCIA DA MATRÍCULA COM RESERVA (80%)¿
       Exemplo candidato 5457993
       */
       --       Exemplo candidato 5457993    
       ,
       ( select sum(cm.val_restituicao) 
           from   sia.credito_mensalidade cm 
           where  cm.num_seq_candidato = ae.num_seq_candidato
           and    cm.cod_motivo_credito = 70
           and    cm.ind_situacao_credito in ('1','2') 
       ) tot_cred_manual_70_candidato
       ,
       ( select sum(cm.val_restituicao) 
           from   sia.credito_mensalidade cm 
           where  cm.num_seq_aluno_curso = ae.num_seq_aluno_curso
           and    cm.cod_motivo_credito = 70
           and    cm.ind_situacao_credito in ('1','2') 
       ) tot_cred_manual_70_aluno
       
                    
    from sia.acordo_especial ae, 
         sia.tipo_acordo_especial tp
         
    --    ind_situacao = 8 ( acordo confirmado )     
    where ae.ind_situacao = '8' 
    --    cod_tipo_acordo_especial = '4' ( DIS atual )
    and   ae.cod_tipo_acordo_especial = '4'     
    --and   ae.num_seq_acordo_especial = 1092328  
    
    --    ***    Limitar a base de testes    ***
 
      
      and   ae.num_seq_acordo_especial in  

                    --   . Exemplos para testes
      (
      
       -- 1097659
     /*          
        '1095057'
        ,'1089256'
        ,'1089257'
        ,'1097659'
     */         
      
         '1089256' -- , '1089257'
         
      /*
          '1094035' --   . Acordo com Carne negociado :             
        , '1095030' --   . Acordo com credito 113 :
        , '1090603' --   . Acordo com Credito 19 mensagem 1 :
        , '1090603' --   . Acordo com Credito 19 mensagem 2 : 
      */
      /*
       '1089457'
      , '1097659'
      , '1095057'
      , '1096917'
      , '2088433'
      , '2088434'
      , '2065651'
      , '1088761'
      , '617783'
      , '578250'
      , '1063580'
      , '1091976'
      , '1089256'
      , '1089257'
      , '227298'
      , '1090603'
      , '1090602'
      */
      )


        
    and   ae.cod_tipo_acordo_especial = tp.cod_tipo_acordo_especial 
    and   ( (select car.val_a_pagar  
                from sia.carne car , 
                     sia.acordo_especial_titulos aet 
                where aet.ind_relacao = 0
                and   aet.num_seq_acordo_especial = ae.num_seq_acordo_especial 
                and   aet.num_seq_carne = car.num_seq_carne 
               )  
               -
               (select sum( dm.val_a_receber ) 
                from sia.acordo_especial_titulos aet, 
                     sia.debito_mensalidade dm 
                where aet.ind_relacao = 2
                and   aet.num_seq_debito_mensalidade = dm.num_seq_debito_mensalidade 
                and   aet.num_seq_acordo_especial = ae.num_seq_acordo_especial
                and   dm.ind_situacao_debito <> '3'
               )  
               ) < 0  ;

  /*
    1 - Selecionar todos os débitos mensalidade do acordo com   
      situacao_debito diferente de cancelado
      ordernados pelos campos num_seq_debito_mensal , dm.dt_mes_ano_referencia
  */
  cursor cursorDebitoMensalidade(pAcordo in number) is
    select dm.num_seq_debito_mensalidade 
           , dm.dt_mes_ano_referencia 
           , dm.val_a_receber 
           , 
           -- AV 20200203
           dm.dt_vencimento
           , dm.num_seq_periodo_academico SeqPeriodo
           , dm.num_seq_aluno_curso
           , dm.num_seq_grupo
           , dm.num_seq_candidato
           , dm.num_seq_aluno_turma_extensao SeqTurmaExt
           , dm.cod_usuario_acerto
           , dm.txt_ip_log           
           ,
           --
           (select car2.val_a_pagar 
           from    sia.carne car2 , 
                   sia.acordo_especial_titulos aet2
            where  aet2.ind_relacao = 0
            and    aet2.num_seq_acordo_especial = aet.num_seq_acordo_especial 
            and    aet2.num_seq_carne = car2.num_seq_carne 
            ) valor_carne    
            ,
            dm.ind_situacao_debito  
            , 
            (select decode(car3.ind_situacao_carne , '1','pendente', '2','baixado', 'cancelado') 
            from sia.carne car3, 
                 sia.debito_credito_consumido dcc3
            where car3.num_seq_carne = dcc3.num_seq_carne 
            and   dcc3.num_seq_debito_mensalidade = dm.num_seq_debito_mensalidade
            )situacao_carne
            , 
            (select car3.val_pago 
            from sia.carne car3, 
                 sia.debito_credito_consumido dcc3
            where car3.num_seq_carne = dcc3.num_seq_carne 
            and   dcc3.num_seq_debito_mensalidade = dm.num_seq_debito_mensalidade
            ) valor_pago 
             ,
           (select tb.nom_tipo_baixa 
            from sia.carne car3, 
                 sia.debito_credito_consumido dcc3, 
                 sur.tipo_baixa tb 
            where car3.num_seq_carne = dcc3.num_seq_carne 
            and   dcc3.num_seq_debito_mensalidade = dm.num_seq_debito_mensalidade
            and   car3.ind_tipo_baixa = tb.cod_tipo_baixa 
            )  tipo_baixa
            ,
           (select sum(cm.val_restituicao) --- cm.num_seq_credito_mensalidade 
           from sia.credito_mensalidade cm 
           where cm.num_seq_aluno_curso = ae.num_seq_aluno_curso 
           and   cm.val_restituicao = dm.val_a_receber
           and   cm.txt_credito_mensalidade = 'DEVOLUÇÃO POR PAGAMENTO DE PARCELA CANCELADA DO DIS COBRADA DE FORMA RETROATIVA'
           and   cm.cod_motivo_credito in( '19', '113')
           and   cm.ind_situacao_credito in ('1','2') 
           and   cm.dt_mes_ano_referencia = dm.dt_mes_ano_referencia 
           ) valor_tot_cred_nesse_valor -----??????????????????????????????????????????
           
    from  sia.acordo_especial_titulos aet ,
          sia.debito_mensalidade dm , 
          sia.acordo_especial ae 
    where dm.num_seq_debito_mensalidade = aet.num_seq_debito_mensalidade 
    and   ae.num_seq_acordo_especial = aet.num_seq_acordo_especial 
    and   dm.ind_situacao_debito <> '3'     
    and   aet.num_seq_acordo_especial = pAcordo
    /*
    and   aet.num_seq_acordo_especial in
    (    
        1090602
        , 1090603
        , 1094704
        , 1094705
        , 1089257
        , 1089256
        , 1142688
        , 1091976
        , 1096166
        , 1096172
        , 1096839
        , 578250
        , 1099218
        , 1092898    
        , 1088761
    ) */   
    -- TODO: Remover esta linha
    -- and   aet.Num_Seq_Debito_Mensalidade = 167221140        
    order by aet.num_seq_acordo_especial, dm.num_seq_debito_mensalidade , dm.dt_mes_ano_referencia; 

  cDM cursorDebitoMensalidade%Rowtype;


  
  function CarneFoiNegociado( pCarne in number ) return pls_integer
  is
    MyRetornoCarneFoiNegociado integer;
  begin
    MyRetornoCarneFoiNegociado := 0;
    
    
    select count(1)
    into   MyRetornoCarneFoiNegociado
    from   sia.acordo_titulos acot
    join   sia.carne carn on carn.num_seq_carne = acot.num_seq_carne
    and    carn.ind_tipo_baixa = 3
    where  acot.ind_relacao = 0
    and    acot.num_seq_carne = pCarne;
  
    return MyRetornoCarneFoiNegociado;
    
  end;            

  function PessoaTemCredito( pMotivoCredito in number
                             , pAluno       in number
                             , pCandidato   in number     
                             , pComplemento in varchar2       
   ) return pls_integer
  is
    MyRetornoPessoaTemCredito integer;    
    MyComplemento varchar2(100);
  begin
 
    --MyComplemento := nvl( '%' || pComplemento || '%', pComplemento );     
    
    if pComplemento is not null then
      MyComplemento := '%' || pComplemento || '%';
    else 
      MyComplemento := pComplemento;
    end if;    
     
    MyRetornoPessoaTemCredito := 0;
    -- preciso avaliar se aluno ou candidato possuem o credito

    select count(1)
    into   MyRetornoPessoaTemCredito
    from   sia.credito_mensalidade crme
    where  crme.ind_situacao_credito < 3
    and    crme.cod_motivo_credito = pMotivoCredito    
    and    crme.txt_credito_mensalidade like MyComplemento
    and    (
                 crme.num_seq_aluno_curso = pAluno
              or crme.num_seq_candidato = pCandidato
              
           ) ;
           
    return MyRetornoPessoaTemCredito;

  end;

  function ExecutarTratativa return pls_integer
  is
    MyRetornoExecutarTratativa integer;
    MyValorPago number(15,2);

    
    function InserirCredito( pValorCredito in number 
                            ) return pls_integer
                              
    --as
    is
      --MyActionSql varchar2(2500);
      MySequencial integer;
      --MyRetorno integer;
      MyCreditoExiste integer;
        
    begin
      MyPoint := 5;
      MyCreditoExiste := 0;
      MyIpLog := cDM.Txt_Ip_Log;
            
      /*
      AV 20200417
      *** Primeira execução não precisa verificar se o num_seq_debito_origem existe
      *** Como essa consulta é muito lenta eu retirei a verificação
            
      select count(1)
      into   MyCreditoExiste
      from   sia.credito_mensalidade crme
      where  crme.num_seq_debito_origem = cDM.Num_Seq_Debito_Mensalidade;
      */    
        
      if MyCreditoExiste = 0 then
          
        select sia.s_credito_mensalidade.nextval into MySequencial
        from   dual;
          
        -- ***
        
        /*  
        insert into sia.credito_mensalidade
        ( num_seq_periodo_academico
          , cod_moeda
          , cod_motivo_credito
          , txt_credito_mensalidade
          , dt_vencimento
          , dt_restituicao
          , val_restituido
          , val_credito_extendido
          , ind_situacao_credito
          , ind_forma_restituicao
          , dt_mes_ano_referencia
          , ind_tipo_credito
          , num_seq_aluno_curso
          , val_restituicao
          , cod_curso
          , num_seq_grupo
          , num_seq_candidato
          , num_seq_aluno_turma_extensao
          , num_cheque
          , num_seq_credito_mensalidade
          , cod_usuario_log
          , dt_atualiza_log
          , txt_ip_log
          , num_seq_inscricao
          , cod_usuario_acerto
          , dt_usuario_acerto
          , num_seq_ocorrencia
          , dt_cancelamento
          , cod_usuario_cancel
          , cod_rubrica_r3
          , cod_usuario_inclusao
          , dt_inclusao
          , cod_concessionaria
          , cod_concessionaria_r3
          , id_instituicao_mig
          , cod_disciplina
          , ind_mov_disciplina
          , num_seq_debito_origem
        )
        values 
        ( null                                   --  num_seq_periodo_academico
          , '9'                                  --  cod_moeda
          , '19'                                 --  cod_motivo_credito
          , 'DEVOLUÇÃO POR PAGAMENTO DE PARCELA CANCELADA DO DIS COBRADA DE FORMA RETROATIVA' --  txt_credito_mensalidade
          , cDM.dt_vencimento                    --  dt_vencimento
          , null                                 --  dt_restituicao
          , 0                                    --  val_restituido
          , null                                 --  val_credito_extendido
          , '1'                                  --  ind_situacao_credito
          , null                                 --  ind_forma_restituicao
          , to_date('02/01/2020', 'dd/mm/yyyy' ) -- cDM.dt_mes_ano_referencia       --  dt_mes_ano_referencia
          , '1'                                --  ind_tipo_credito
          , cDM.num_seq_aluno_curso            --  num_seq_aluno_curso
          , pValorCredito                      -- cDM.val_a_receber --  val_restituicao
          , null                               --  cod_curso ***
          , cDM.num_seq_grupo                  --  num_seq_grupo
          , cDM.num_seq_candidato              --  num_seq_candidato
          , cDM.SeqTurmaExt                    --  num_seq_aluno_turma_extensao
          , null                               --  num_cheque ***
          , MySequencial                       --  num_seq_credito_mensalidade
          , '1016283'                          --  cod_usuario_log
          , sysdate                            --  dt_atualiza_log
          , '10.8.2.147'                       --  txt_ip_log ***
          , null                               --  num_seq_inscricao
          , null                               --  cod_usuario_acerto
          , null                               --  dt_usuario_acerto
          , null                               --  num_seq_ocorrencia
          , null                               --  dt_cancelamento
          , null                               --  cod_usuario_cancel
          , '179'                              --  cod_rubrica_r3
          , '93778848704'                      --  cod_usuario_inclusao
          , sysdate                            --  dt_inclusao
          , null                               --  cod_concessionaria
          , null                               --  cod_concessionaria_r3
          , null                               --  id_instituicao_mig
          , null                               --  cod_disciplina
          , null                               --  ind_mov_disciplina
          , cDM.num_seq_debito_mensalidade     -- num_seq_debito_mensalidadeorigem
        );
        commit;    
        */  
                           
      end if;
                
      return MyCreditoExiste;
        
    exception
      when others then
        rollback;

        ErrOracle := sqlcode || ' - ' || SqlErrm;

        seg.seg_log_execucao( 'PRB45-TRATATIVA'
                              , MyPoint
                              , ErrOracle
                              , MyParam
                              , sqlerrm);
                
        raise_application_error( -20001
                                  , 'Erro na PRB45-TRATATIVAPRB45' 
                                  || ErrOracle 
                                  || ' Posicao= '     || MyPoint
                                  || ' Erro_oracle= ' || SqlCode 
                                  || ' sqlerrm = '    || SqlErrm);
                                   
        return 0;
      
    end; -- InserirCredito;
       
    function AlterarDebito return pls_integer  
    is
      --MyIpLog varchar2(10);
        
    begin
      MyPoint := 6;
        
      -- ***
      
      /*  
      update SIA.debito_mensalidade deme
      set    deme.ind_situacao_debito = 3    
      where  deme.ind_situacao_debito = 1
      and    deme.num_seq_debito_mensalidade = cDM.num_seq_debito_mensalidade ;
          
      commit;
      */  
      
        
      return 1;
      
    exception
      when others then
        rollback;
        ErrOracle := sqlcode || ' - ' || Sqlerrm;

        seg.seg_log_execucao( 'PRB45-TRATATIVA'
                              , MyPoint
                              , ErrOracle
                              , MyParam
                              , sqlerrm);
       
        raise_application_error( -20001
                                  , 'Erro na PRB45-TRATATIVAPRB45' 
                                  || ErrOracle 
                                  || ' Posicao= '     || MyPoint
                                  || ' Erro_oracle= ' || SqlCode 
                                  || ' sqlerrm = '    || SqlErrm);
                   
        return 0;
      
    end; -- AlterarDebito;  
      
    
  begin
    MyRetornoExecutarTratativa := 0;
    MyValorPago := 0;
    
    -- Substituir  item.cod_matricula  por MyMatricula
    -- [ *** inicio ExecutarTratativa
    
    
    MySum := 0;    
    MyPoint := 2;

    /*
      Selecionar todos os débitos mensalidade do acordo com  
      situacao_debito diferente de cancelado
      ordernados pelos campos num_seq_debito_mensal , dm.dt_mes_ano_referencia  	
    */
    open cursorDebitoMensalidade( MyAcordo );
    loop
      fetch cursorDebitoMensalidade into cDM;
      exit when cursorDebitoMensalidade%notfound;
    
      MyValorPago := cDM.Valor_Pago;
        
      -- Somar valor do debito mensalidade 
      MySum := MySum + cDM.Val_a_Receber;
      
      -- 2 - Quando o somatório dos val_a_receber > valor_carne , para cada débito verificar:
      if MySum > MyCarneValor then
        
        -- Situação questionada por mim em 20200326 *** Em conversa com o Lazaro entendi que pode ocorrer no futuro       
        select count(1)
        into   MyFormado
        from   sia.aluno_periodo alp
        where  alp.num_seq_aluno_curso = cDM.Num_Seq_Aluno_Curso
        and    alp.cod_situacao_periodo = 52;
        
        if MyFormado != 0 then
        -- Tratar alunos que, embora tenham direito a creditos, ja estão formados   
          MyPoint := 3;
          MySummary( 1 ).Summary := MySummary( 1 ).Summary + 1;        

          dbms_output.put_line( MyMatricula || ';' || MySummary( 1 ).Description || ';' || MyCarne || ';' || cDM.Num_Seq_Debito_Mensalidade || ';' || MyAcordo || ';' || MyTxtNossoNumero );
               
        end if;
        
        /*        
          e-mail da Ana 20200403 1300
          
          Gostaria de pedir o seu de acordo em relação ao crédito no motivo 
          19 (DEVOLUÇÃO POR  PAGAMENTO DE MENSALIDADE (AUTOMATICO)). 
          Assim como na PRB 161, os alunos com crédito lançado no 
          motivo 19  e 113 (ACERTO DIS), não seriam tratados pelo script. 
          Porém, verifiquei que tem alunos com 
            
          crédito no motivo 19, que 
          não é referente ao DIS
           e sim apenas a uma mensalidade paga a maior, 
             
          como é o caso do exemplo anexado. Dessa forma, para que esses alunos 
          não sejam excluídos da correção, gostaria de propor uma melhoria na 
          pesquisa do motivo 19, seguindo-se pelo texto na 
          observação “Crédito para acerto de pagamento a maior no carnê:”. 
          Para que os alunos que possuam crédito no motivo 19, seguido 
          por essa observação sejam tratados pelo script.
          Exemplo 2018558724934                                    
        */
        select count(1)
        into   MyCredito19
        from   sia.credito_mensalidade cm 
        where  1=1
        and    upper( cm.txt_credito_mensalidade ) like '%DITO PARA ACERTO DE PAGAMENTO A MAIOR NO%'
        and    cm.cod_motivo_credito = '19'
        and    cm.ind_situacao_credito in ('1','2')
        and    cm.num_seq_aluno_curso = cDM.Num_Seq_Aluno_Curso;
        
        
        if MyCredito19 != 0 then
        -- Tratar Crédito para acerto de pagamento a maior   
          MyPoint := 3;
          MySummary( 2 ).Summary := MySummary( 2 ).Summary + 1;        
          
          dbms_output.put_line( MyMatricula || '; 2-' || MySummary( 2 ).Description || ';' || MyCarne || ';' || cDM.Num_Seq_Debito_Mensalidade || ';' || MyAcordo || ';' || MyTxtNossoNumero );

        end if;
        
                    
        if cDM.ind_situacao_debito = 1 then
        --  2.1 Cancelar os débitos não consumidos com ind_situacao_debito =1, 
        -- ou alterar a situacao_debito de 1 para 3.        
          MyPoint := 4;        
          MyReturn := AlterarDebito;
          MySummary( 3 ).Summary := MySummary( 3 ).Summary + 1;        

          dbms_output.put_line( MyMatricula || ';' || MySummary( 3 ).Description || ';' || MyCarne || ';' || cDM.Num_Seq_Debito_Mensalidade || ';' || MyAcordo || ';' || MyTxtNossoNumero );


        elsif cDM.ind_situacao_debito = 2 and MyValorPago is not null then          
        -- 2.2 Lançar um crédito mensalidade para cada débito mensalidade consumido, ind_situacao_debito = 2, 
        -- com os dados abaixo:         
          MyPoint := 5;        
          MyReturn := InserirCredito( cDM.Val_a_Receber );
          
          if MyReturn != 0 then
             -- Credito já existe   
             dbms_output.put_line( MyMatricula || ';' || 'CREDITO JA EXISTE' || ';' || MyCarne || ';' || cDM.Num_Seq_Debito_Mensalidade || ';' || MyAcordo || ';' || MyTxtNossoNumero );

          else           
            MySummary( 4 ).Summary := MySummary( 4 ).Summary + 1;        

            dbms_output.put_line( MyMatricula || ';' || MySummary( 4 ).Description || ';' || MyCarne || ';' || cDM.Num_Seq_Debito_Mensalidade || ';' || MyAcordo || ';' || MyTxtNossoNumero );
              
          end if;
            
                   
        elsif cDM.Situacao_Carne = 'pendente' then
        --// *** 
        --// implentar aqui o email do Tiago
        --// chamar uma proc para cancelar o carne (conforme orientação da Marcia)
        --// Abaixo o e-mail
        /*
           Os carnês pendentes devem ser cancelados. Gerar crédito, caso não consiga cancelar.
           Os carnês negociados devem ser enviados para análise da área de negócio, pois podem ter concedido desconto na negociação.
        */   
        --// Perguntei à Marcia qual a ordem e ela informou que era pra implementar aqui
        --  '1','pendente', '2','baixado', 'cancelado'        
          MyPoint := 6;        
          MySummary( 5 ).Summary := MySummary( 5 ).Summary + 1;        
          
          dbms_output.put_line( MyMatricula || ';' || MySummary( 5 ).Description || ';' || MyCarne || ';' || cDM.Num_Seq_Debito_Mensalidade || ';' || MyAcordo || ';' || MyTxtNossoNumero );

          /*
             Se não conseguir cancelar entao
             gerar credito
          */                      
          sia.fin_cancela_carne( MyCarne
                                 , MyIndErro
                                 , MyError
                                 , null
                                 , cDM.Num_Seq_Aluno_Curso
                                 , null
                                 , MyCandidato
                                 , sysdate -- *** A confirmar ***
                               ) ;  
                               
          
                 
          if MyIndErro <> '0' then 
            MyReturn := InserirCredito(cDM.Val_a_Receber);
            
            if MyReturn != 0 then
              -- Credito já existe   
              dbms_output.put_line( MyMatricula || ';' || 'CREDITO JA EXISTE' || ';' || MyCarne || ';' || cDM.Num_Seq_Debito_Mensalidade || ';' || MyAcordo || ';' || MyTxtNossoNumero );

            else 
     
              MySummary( 6 ).Summary := MySummary( 6 ).Summary + 1;        

              dbms_output.put_line( MyMatricula || ';' || MySummary( 6 ).Description || ';' || MyCarne || ';' || cDM.Num_Seq_Debito_Mensalidade || ';' || MyAcordo || ';' || MyTxtNossoNumero );

            end if;  
          end if;            
                        
        else 
          -- gerar relacao *** 
          -- incluir MyAcordo, item.valor_divida_antiga, cDM.Valor_Pago, cDM.Situacao_Carne, MySum, cDM.ind_situacao_debito
          MyPoint := 7;                  
          MySummary( 7 ).Summary := MySummary( 7 ).Summary + 1;        

          dbms_output.put_line( MyMatricula || ';' || MySummary( 7 ).Description || ';' || MyCarne || ';' || cDM.Num_Seq_Debito_Mensalidade || ';' || MyAcordo || ';' || MyTxtNossoNumero );

        end if;                                
        --]                          
      end if;   -- if MySum > item.valor_divida_antiga
                 
    end loop;
    
    close cursorDebitoMensalidade;
    
    
    -- fim ExecutarTratativa ***]
    
    
    return MyRetornoExecutarTratativa;
  end;  

  function GerarAnalise return pls_integer
  is
    MyRetornoGerarAnalise integer;
  begin
    MyRetornoGerarAnalise := 0;

    MyPoint := 7;                  
    MySummary( 7 ).Summary := MySummary( 7 ).Summary + 1;        

    dbms_output.put_line( MyMatricula || ';' || MySummary( 7 ).Description || ';' || MyCarne || ';' || cDM.Num_Seq_Debito_Mensalidade || ';' || MyAcordo || ';' || MyTxtNossoNumero );
    
    return MyRetornoGerarAnalise;
  end;  
  
begin

  dbms_application_info.set_client_info( '1016283@estacio');      
  dbms_output.enable (buffer_size => null);

  dbms_output.put_line( 'ALUNO;REGRA_RESULTADO;CARNE;DEBITO;ACORDO;NOSSO_NUMERO' );
  
   
  -- Inicializar as variaveis e matrizes
  MyPoint := 1;
  MyParam := '';  
  
  My_1_TextoCredito19 := 'DEVOLUÇÃO POR PAGAMENTO DE PARCELA CANCELADA DO DIS COBRADA DE FORMA RETROATIVA';
  My_2_TextoCredito19 := 'CRÉDITO PARA ACERTO DE PAGAMENTO A MAIOR NO CARNÊ';
  
  MyCount := MyDescription.last;

  for MyIndex in MyDescription.first .. MyCount loop   
     
    MySummary( MyIndex ).Id := MyIndex;
    MySummary( MyIndex ).Description := MyDescription(MyIndex);
    MySummary( MyIndex ).Summary := 0;
    
  end loop;
    
  
  /* 0 - Listar 
      Para cada acordo especial DIS ATUAL confirmado 
      E valor carne menos (-) somatório dos debitos mensalidades 
      ( com situação diferente de cancelado ) for menor que zero
  */    
  for item in cursorAcordo loop
    MySum := 0;    
    MyPoint := 2;

    MyAcordo := item.num_seq_acordo_especial;
    MyCarne  := item.num_seq_carne;
    MyMatricula := item.cod_matricula;    
    MyCandidato := item.num_seq_candidato;
    MyCarneValor := item.valor_divida_antiga;

            
    --[ *** inicio do novo algoritmo *** ]--

    /* Salvar o txt_nosso_numero */
    select txt_nosso_numero
    into   MyTxtNossoNumero
    from   sia.carne carn
    where  carn.num_seq_carne = MyCarne;


    /*
    -- *** Como saber se a pessoa tem negociação *** --
    -- *** Vide tratativa do carne pendente fala sobre o carne negociado *** -- 
    
       Os carnês negociados devem ser enviados para análise da área de negócio, pois podem ter concedido desconto na negociação.
    */   
    if CarneFoiNegociado( MyCarne ) = 0 then
      
      /* Crédito motivo 70
        . Se houver crédito motivo 70 então desprezar
        . SeNão desprezar
      */
      
      /* Crédito motivo 113
        . Se o valor for igual a zero então Tratativa conforme item 1
        . SeNão enviar para análise
      */  
      if PessoaTemCredito( 113
                           , item.Num_Seq_Aluno_Curso
                           , item.Num_Seq_Candidato 
                           , null                          ) > 0 then

        if nvl( item.Tot_Cred_Manual_113_Aluno, 0 ) + 
           nvl( item.Tot_Cred_Manual_113_Candidato, 0 ) = 0 then
          MyReturn := ExecutarTratativa;
          
        else  
          MyReturn := GerarAnalise;
                
        end if;  
         
      /* Crédito motivo 19
        Com texto 'DEVOLUÇÃO POR PAGAMENTO DE PARCELA CANCELADA DO DIS COBRADA DE FORMA RETROATIVA'
        . Se o valor for igual a zero então Tratativa conforme item 1
        . SeNão enviar para análise
      */   
      elsif PessoaTemCredito( 19  
                           , item.Num_Seq_Aluno_Curso
                           , item.Num_Seq_Candidato 
                           , My_1_TextoCredito19           ) > 0 then
        
        if nvl( item.Valor_Tot_Cred_Aluno, 0 ) + 
           nvl( item.Valor_Tot_Cred_Candidato, 0 ) = 0 then
          MyReturn := ExecutarTratativa;
          
        else  
          MyReturn := GerarAnalise;
                
        end if;  
      
      else 
        MyReturn := ExecutarTratativa;
          
      end if;  



    else 
      MyReturn := GerarAnalise;
    
    end if;


    
    --[ *** fim do novo algoritmo *** ]--
    
    

    MySum := 0;

  end loop;

  /*  Totalizadores
  */
  dbms_output.put_line( 'Descricao; Total; ' );

  for MyIndex in MyDescription.first .. MyCount -1 loop   
    
    -- Somando o total de linhas analisadas
    MySummary(MyCount).Summary := MySummary(MyCount).Summary + MySummary(MyIndex+1).Summary; 
    
    dbms_output.put_line( MySummary( MyIndex+1 ).Description || ';' || MySummary( MyIndex+1 ).Summary || ';' );    
      
  end loop;
  
  -- Exibir o total de linhas analisadas  
  dbms_output.put_line( MySummary( MyCount ).Description || ';' || MySummary( MyCount ).Summary || ';' );    

exception
  when others then
      ErrOracle := sqlcode || ' - ' || Sqlerrm;

      --                     PROCTRATATIVA 
      seg.seg_log_execucao( 'PRB45-TRATATIVA'
                            , MyPoint
                            , ErrOracle
                            , MyParam
                            , sqlerrm);
end;
/
