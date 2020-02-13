create or replace procedure sia.ProcTratativa(
                                                pNumeroAcordo in PLS_INTEGER
                                              )
is
  -- Created on 04/02/2020 by ALUGA.COM 
  --declare 
  -- Local variables here

  MySum number;
  --MyCount number;
  MyPoint number;
  MyAcordo number;
  MyReturn number;
  MyIpLog varchar2(100);

  MyParam varchar2(500);
  ErrOracle varchar2(3700);


  /*
      Consulta atualizada pelo 
      e-mail Marcia Nepomuceno do Amaral <marcia.amaral.ter@estacio.br>
      em sexta-feira, 7 de fevereiro de 2020 16:58
      Para Antal Varga  
      
  */
  -- 0- Para cada acordo listado :
  cursor cursorAcordo is
    select ae.num_seq_acordo_especial 
           , ae.cod_tipo_acordo_especial
           , tp.nom_tipo_acordo_especial 
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
           , 
           ae.dt_acordo_especial 
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
         -- 			Exemplo candidato 5457993    
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
         
    where ae.ind_situacao = '8' 
    and   ae.cod_tipo_acordo_especial = '4'     
--    and   ae.num_seq_acordo_especial = 578250 -- 1088761 -- MyAcordo ----------------exemplo 
    
    and   ae.num_seq_acordo_especial in  
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




  -- 1 - selecionar todos os débitos mensalidade do acordo com  dm.ind_situacao_debito <> '3'
  -- orderndos pelos campos dm.num_seq_debito_mensal , dm.dt_mes_ano_referencia
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
            where  aet.ind_relacao = 0
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

  --
  cDM cursorDebitoMensalidade%Rowtype;
    

  function InserirCredito( pValorCredito in number 
                           , pOperacao   in varchar2                            
                          ) return pls_integer
                          
  --as
  is
    MyActionSql varchar2(2500);
    MySequencial integer;
    
  begin
    MyPoint := 5;
    MyIpLog := cDM.Txt_Ip_Log;
              
    dbms_output.put_line( '2.2 = ' || cDM.Num_Seq_Debito_Mensalidade );
    
    select sia.s_credito_mensalidade.nextval into MySequencial
    from   dual;
    
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
    ( null               --  num_seq_periodo_academico
      , '9'                       --  cod_moeda
      , '19'                      --  cod_motivo_credito
      , 'DEVOLUÇÃO POR PAGAMENTO DE PARCELA CANCELADA DO DIS COBRADA DE FORMA RETROATIVA' --  txt_credito_mensalidade
      , cDM.dt_vencimento         --  dt_vencimento
      , null                          --  dt_restituicao
      , 0                            --  val_restituido
      , null                            --  val_credito_extendido
      , '1'                             --  ind_situacao_credito
      , null                            --  ind_forma_restituicao
      , cDM.dt_mes_ano_referencia       --  dt_mes_ano_referencia
      , '1'                             --  ind_tipo_credito
      , cDM.num_seq_aluno_curso         --  num_seq_aluno_curso
      , cDM.val_a_receber               --  val_restituicao
      , null                            --  cod_curso ***
      , cDM.num_seq_grupo                --  num_seq_grupo
      , cDM.num_seq_candidato            --  num_seq_candidato
      , cDM.SeqTurmaExt --  num_seq_aluno_turma_extensao
      , null                            --  num_cheque ***
      , MySequencial                    --  num_seq_credito_mensalidade
      , '1016283'                       --  cod_usuario_log
      , sysdate                         --  dt_atualiza_log
      , '10.8.2.147'                         --  txt_ip_log ***
      , null                            --  num_seq_inscricao
      , null                            --  cod_usuario_acerto
      , null                            --  dt_usuario_acerto
      , null                            --  num_seq_ocorrencia
      , null                            --  dt_cancelamento
      , null                            --  cod_usuario_cancel
      , '179'                           --  cod_rubrica_r3
      , '93778848704'                   --  cod_usuario_inclusao
      , sysdate                         --  dt_inclusao
      , null                            --  cod_concessionaria
      , null                            --  cod_concessionaria_r3
      , null                            --  id_instituicao_mig
      , null                            --  cod_disciplina
      , null                            --  ind_mov_disciplina
      , cDM.num_seq_debito_mensalidade  -- num_seq_debito_mensalidadeorigem
    );
    commit;    
      

    /* RETIRAR */
      --raise_application_error( -20001, 'Erro na ProcTratativaPRB45' );

    
    return 1;
  
  exception
    when others then
      rollback;

      ErrOracle := sqlcode || ' - ' || SqlErrm;

      seg.seg_log_execucao( 'PROCTRATATIVA'
                            , MyPoint
                            , ErrOracle
                            , MyParam
                            , sqlerrm);
            
      raise_application_error( -20001
                                , 'Erro na ProcTratativaPRB45' 
                                || ErrOracle 
                                || ' Posicao= '     || MyPoint
                                || ' Erro_oracle= ' || SqlCode 
                                || ' sqlerrm = '    || SqlErrm);
                               
      return 0;
  
  end; -- InserirCredito;
  --  
  
  -- 
  function AlterarDebito return pls_integer
  
  is
    --MyIpLog varchar2(10);
    
  begin
    MyPoint := 6;
    dbms_output.put_line( '2.1 = ' || cDM.Num_Seq_Debito_Mensalidade);

/*
    update SIA.debito_mensalidade deme
    set    deme.ind_situacao_debito = 3    
    where  deme.ind_situacao_debito = 1
    and    deme.num_seq_debito_mensalidade = cDM.num_seq_debito_mensalidade ;
*/      
    --commit;
    return 1;
  
  exception
    when others then
      rollback;
      ErrOracle := sqlcode || ' - ' || Sqlerrm;

      seg.seg_log_execucao( 'PROCTRATATIVA'
                            , MyPoint
                            , ErrOracle
                            , MyParam
                            , sqlerrm);
   
      raise_application_error( -20001
                                , 'Erro na ProcTratativaPRB45' 
                                || ErrOracle 
                                || ' Posicao= '     || MyPoint
                                || ' Erro_oracle= ' || SqlCode 
                                || ' sqlerrm = '    || SqlErrm);
               
      return 0;
  
  end; -- AlterarDebito;
  --  



  function CriarRastreabilidade return pls_integer
  
  is
    MyResult pls_integer;
    MyActionSql varchar2(500);
    
  begin
    MyPoint := 7;

    select count(1)
    into   MyResult
    from   all_tab_columns
    where  1=1
    and    column_name = 'NUM_SEQ_CRED_ORIGEM'
    and    upper( table_name ) = 'CREDITO_MENSALIDADE'
    and    owner = 'SIA';
      
    if MyResult <> 1 then
      
      MyActionSql := 'alter table sia.credito_mensalidade add NUM_SEQ_CRED_ORIGEM number;';
      
      dbms_output.put_line( MyActionSql );
      --execute immediate MyActionSql; 
      -- Erro ao executar devido à permissao
            
    end if;

    return 1;
  
  exception
    when others then
      rollback;
      ErrOracle := sqlcode || ' - ' || Sqlerrm;
      /*
      seg.seg_log_execucao( 'PROCTRATATIVA'
                            , MyPoint
                            , ErrOracle
                            , MyParam
                            , sqlerrm);
      */                      
      raise_application_error( -20001
                                , 'Erro na ProcTratativaPRB45' 
                                || ErrOracle 
                                || ' Posicao= '     || MyPoint
                                || ' Erro_oracle= ' || SqlCode 
                                || ' sqlerrm = '    || SqlErrm);
               
      return 0;
  
  end; -- CriarRastreabilidade();




begin

  dbms_application_info.set_client_info( '1016283@estacio');
    
  --execute immediate 'alter session set nls_language  = ''BRAZILIAN PORTUGUESE''';
  --execute immediate 'alter session set nls_territory = ''BRAZIL''';
  execute immediate 'alter session set nls_numeric_characters = ''.,''';

 /*
  if pNumeroAcordo is not null then
    MyAcordo := pNumeroAcordo;

  end if;
*/
  MyPoint := 1;
  MyParam := '';
  --MyCount := 0;
  
  MyReturn := CriarRastreabilidade();  

-- 1 ¿ Para cada acordo a maior, selecionar todos os débitos mensalidade 
-- com dm.ind_situacao_debito <> '3',orderndos pelo campo dm.num_seq_debito_mensalidade.  
  for item in cursorAcordo loop
    MyAcordo := item.num_seq_acordo_especial;

    dbms_output.put_line( MyAcordo );

    MySum := 0;    
    MyPoint := 2;
/*
    for MyCount in 1..MyOpera.count loop
      MyOpera( MyCount ) := 0;
    end loop;    
*/    
    -- Abrir cursor Num_Seq_Debito_Mensalidade
    open cursorDebitoMensalidade( MyAcordo );
    loop
      fetch cursorDebitoMensalidade into cDM;

      exit when cursorDebitoMensalidade%notfound;
      
      MySum := MySum + cDM.Val_a_Receber;
      
      -- 2 - Quando o somatório dos val_a_receber > valor_carne , para cada débito verificar:
      if MySum > item.valor_divida_antiga then
        
        --  2.1 Cancelar os débitos não consumidos com ind_situacao_debito =1, 
        -- ou alterar a situacao_debito de 1 para 3.
        if cDM.ind_situacao_debito = 1 then

          MyReturn := AlterarDebito();

         MySum := MySum;
          
        end if;  
                      
        -- 2.2 Lançar um crédito mensalidade para cada débito mensalidade consumido, ind_situacao_debito = 2, 
        -- com os dados abaixo: 
        if cDM.ind_situacao_debito = 2 and cDM.Valor_Pago is not null then          
          
          MyReturn := InserirCredito( cDM.Val_a_Receber, '2.2' );
                              
        end if;  
          
      end if;

    end loop;
    
    close cursorDebitoMensalidade;
    MySum := 0;

  end loop;

exception
  when others then
      ErrOracle := sqlcode || ' - ' || Sqlerrm;

      seg.seg_log_execucao( 'PROCTRATATIVA'
                            , MyPoint
                            , ErrOracle
                            , MyParam
                            , sqlerrm);
end;
/
