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
      em seg 03/02/2020 11:41
      Para Antal Varga  
      
      Evidencias de que os testes passaram ok
            
      alter table sia.credito_mensalidade add NUM_SEQ_CRED_ORIGEM number
578250
2.2 = 167221137
2.2 = 167221138
2.2 = 167221139
2.2 = 167221140 *
2.2 = 167221140 *
1088761
2.2 = 194735797
2.1 = 194735798
1089256
2.1 = 193268384
2.1 = 193268385
2.1 = 193268386
1089257
2.1 = 193272864
2.1 = 193272865
2.1 = 193272866
1090602
2.2 = 194628188
2.2 = 194628189
2.2 = 194628190
2.2 = 194628191
2.2 = 194628192 *
2.2 = 194628192 *
1090603
2.2 = 194174680
2.2 = 194174681
2.2 = 194174682
2.2 = 194174683
2.2 = 194174684 *
2.2 = 194174684 *
1091976
2.2 = 193914439 
2.2 = 193914440
2.2 = 193914441
2.2 = 193914442
2.2 = 193914443
2.2 = 193914444
2.2 = 193914445
2.2 = 193914446
2.2 = 193914447
2.2 = 193914448
2.2 = 193914449
2.1 = 193914455
2.1 = 193914456
2.1 = 193914457
2.1 = 193914458
2.1 = 193914459
2.1 = 193914460
2.1 = 193914461
2.1 = 193914462
2.1 = 193914463
2.1 = 193914464
2.1 = 193914465
2.1 = 193914466 *
2.1 = 193914466 *
1092898
2.2 = 194196597
2.2 = 194196598
2.1 = 194196601
1094704
2.1 = 193269882
2.1 = 193269883
1094705
2.1 = 193317777
2.1 = 193317778
1096166
1096172
2.2 = 194174257
1096839
1099218
1142688

      
      
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
           where aet.num_seq_acordo_especial = ae.num_seq_acordo_especial 
           and   aet.num_seq_carne = car.num_seq_carne 
           ) valor_divida_antiga 
           ,
          (select sum( dm.val_a_receber ) 
           from sia.acordo_especial_titulos aet, 
                sia.debito_mensalidade dm 
           where aet.num_seq_debito_mensalidade = dm.num_seq_debito_mensalidade 
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
           --and   cm.cod_motivo_credito = '19'
           and   cm.cod_motivo_credito in( '19', '113' )
		   
           and   cm.ind_situacao_credito in ('1','2') 
           ) valor_tot_cred_candidato 
           ,            
           (select sum(cm.val_restituicao) --- cm.num_seq_credito_mensalidade 
           from sia.credito_mensalidade cm 
           where cm.num_seq_aluno_curso = ae.num_seq_aluno_curso 
           and   cm.txt_credito_mensalidade = 'DEVOLUÇÃO POR PAGAMENTO DE PARCELA CANCELADA DO DIS COBRADA DE FORMA RETROATIVA'
           --and   cm.cod_motivo_credito = '19'
           and   cm.cod_motivo_credito in( '19', '113' )
           and   cm.ind_situacao_credito in ('1','2') 
           ) valor_tot_cred_aluno
                     
    from sia.acordo_especial ae, 
         sia.tipo_acordo_especial tp
         
    where ae.ind_situacao = '8' 
    and   ae.cod_tipo_acordo_especial = '4'     
    and   ae.num_seq_acordo_especial = 578250 -- 1088761 -- MyAcordo ----------------exemplo 
/*    
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
*/    
        
    and   ae.cod_tipo_acordo_especial = tp.cod_tipo_acordo_especial 
    and   ( (select car.val_a_pagar  
                from sia.carne car , 
                     sia.acordo_especial_titulos aet 
                where aet.num_seq_acordo_especial = ae.num_seq_acordo_especial 
                and   aet.num_seq_carne = car.num_seq_carne 
               )  
               -
               (select sum( dm.val_a_receber ) 
                from sia.acordo_especial_titulos aet, 
                     sia.debito_mensalidade dm 
                where aet.num_seq_debito_mensalidade = dm.num_seq_debito_mensalidade 
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
           from sia.carne car2 , 
                sia.acordo_especial_titulos aet2
            where aet2.num_seq_acordo_especial = aet.num_seq_acordo_especial 
            and   aet2.num_seq_carne = car2.num_seq_carne 
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
           and   cm.cod_motivo_credito = '19'
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
    
    -- TODO: Remover esta linha
    -- and   aet.Num_Seq_Debito_Mensalidade = 167221140
    
    
    
    order by dm.num_seq_debito_mensalidade , dm.dt_mes_ano_referencia; 

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
     
      MyActionSql :=                ' insert into sia.credito_mensalidade ';
      MyActionSql := MyActionSql || ' ( num_seq_periodo_academico ';
      MyActionSql := MyActionSql || ' , cod_moeda ';
      MyActionSql := MyActionSql || ' , cod_motivo_credito ';
      MyActionSql := MyActionSql || ' , txt_credito_mensalidade ';
      MyActionSql := MyActionSql || ' , dt_vencimento ';
      MyActionSql := MyActionSql || ' , dt_restituicao ';
      MyActionSql := MyActionSql || ' , val_restituido ';
      MyActionSql := MyActionSql || ' , val_credito_extendido ';
      MyActionSql := MyActionSql || ' , ind_situacao_credito ';
      MyActionSql := MyActionSql || ' , ind_forma_restituicao ';
      MyActionSql := MyActionSql || ' , dt_mes_ano_referencia ';
      MyActionSql := MyActionSql || ' , ind_tipo_credito ';
      MyActionSql := MyActionSql || ' , num_seq_aluno_curso ';
      MyActionSql := MyActionSql || ' , val_restituicao ';
      MyActionSql := MyActionSql || ' , cod_curso ';
      MyActionSql := MyActionSql || ' , num_seq_grupo ';
      MyActionSql := MyActionSql || ' , num_seq_candidato ';
      MyActionSql := MyActionSql || ' , num_seq_aluno_turma_extensao ';
      MyActionSql := MyActionSql || ' , num_cheque ';
      MyActionSql := MyActionSql || ' , num_seq_credito_mensalidade ';
      MyActionSql := MyActionSql || ' , cod_usuario_log ';
      MyActionSql := MyActionSql || ' , dt_atualiza_log ';
      MyActionSql := MyActionSql || ' , txt_ip_log ';
      MyActionSql := MyActionSql || ' , num_seq_inscricao ';
      MyActionSql := MyActionSql || ' , cod_usuario_acerto ';
      MyActionSql := MyActionSql || ' , dt_usuario_acerto ';
      MyActionSql := MyActionSql || ' , num_seq_ocorrencia ';
      MyActionSql := MyActionSql || ' , dt_cancelamento ';
      MyActionSql := MyActionSql || ' , cod_usuario_cancel ';
      MyActionSql := MyActionSql || ' , cod_rubrica_r3 ';
      MyActionSql := MyActionSql || ' , cod_usuario_inclusao ';
      MyActionSql := MyActionSql || ' , dt_inclusao ';
      MyActionSql := MyActionSql || ' , cod_concessionaria ';
      MyActionSql := MyActionSql || ' , cod_concessionaria_r3 ';
      MyActionSql := MyActionSql || ' , id_instituicao_mig ';
      MyActionSql := MyActionSql || ' , cod_disciplina ';
      MyActionSql := MyActionSql || ' , ind_mov_disciplina ';
      MyActionSql := MyActionSql || ' , num_seq_debito_origem ';
                              
      MyActionSql := MyActionSql || ' ) values ( ';
       
	  --  num_seq_periodo_academico	
      --MyActionSql := MyActionSql ||     nvl( cDM.Seqperiodo, 'null' ) ; 
	  if cDM.Seqperiodo is null then
	    MyActionSql := MyActionSql ||     'null'; 
	  else
	    MyActionSql := MyActionSql ||     cDM.Seqperiodo; 
	  end if; 	  
	  
	  --  cod_moeda
      MyActionSql := MyActionSql || ' , 9 ';     
	  	
      --  cod_motivo_credito
	  MyActionSql := MyActionSql || ' , 19';                            
      
	  --  txt_credito_mensalidade
	  MyActionSql := MyActionSql || ' , ' || chr(39) || 'DEVOLUÇÃO POR PAGAMENTO DE PARCELA CANCELADA DO DIS COBRADA DE FORMA RETROATIVA' || chr(39);
      
	  --  dt_vencimento
	  MyActionSql := MyActionSql || ' , ' || chr(39) || cDM.dt_vencimento || chr(39) ;            
      
	  --  dt_restituicao
	  MyActionSql := MyActionSql || ' , null ';                            
      
	  --  val_restituido
	  MyActionSql := MyActionSql || ' , 0  ';                              
      
	  --  val_credito_extendido
	  MyActionSql := MyActionSql || ' , null ';                           
      
	  --  ind_situacao_credito
	  MyActionSql := MyActionSql || ' , 1' ;
      
	  --  ind_forma_restituicao
	  MyActionSql := MyActionSql || ' , null ';                                        
      
	  --  dt_mes_ano_referencia
	  MyActionSql := MyActionSql || ' , ' || chr(39) || cDM.dt_mes_ano_referencia || chr(39);      
      
	  --  ind_tipo_credito
	  MyActionSql := MyActionSql || ' , 1'  ;
      
	  --  num_seq_aluno_curso
	  MyActionSql := MyActionSql || ' , ' || cDM.num_seq_aluno_curso;
	  
	  --  val_restituicao/ val receber
      MyActionSql := MyActionSql ||     chr(13) || ' /* cDM.val_a_receber */ ' || chr(13);            	  
	  MyActionSql := MyActionSql || ' , ' || nvl(cDM.val_a_receber,0) ;      
	  
      --  cod_curso ***
      MyActionSql := MyActionSql ||     chr(13) || ' /* cod_curso */ ' || chr(13);            	  
	  MyActionSql := MyActionSql || ' , null ';            
      
	  --  num_seq_grupo
      MyActionSql := MyActionSql ||     chr(13) || ' /* num_seq_grupo */ ' || chr(13);            	  
	  --MyActionSql := MyActionSql || ' , ' || nvl( cDM.num_seq_grupo, null) ;

	  if cDM.num_seq_grupo is null then
	    MyActionSql := MyActionSql ||   ', null'; 
	  else
	    MyActionSql := MyActionSql ||   ',' ||  cDM.num_seq_grupo; 
	  end if; 	  
      
      --  num_seq_candidato
	  MyActionSql := MyActionSql ||     chr(13) || ' /* cDM.num_seq_candidato */ ' || chr(13);            
	  --MyActionSql := MyActionSql || ' , ' || nvl( cDM.num_seq_candidato, null) ;            
            
	  if cDM.num_seq_candidato is null then
	    MyActionSql := MyActionSql ||     ', null'; 
	  else
	    MyActionSql := MyActionSql ||   ',' ||  cDM.num_seq_candidato; 
	  end if; 	  
			
	  --  num_seq_aluno_turma_extensao
      MyActionSql := MyActionSql ||     chr(13) || ' /* num_seq_aluno_turma_extensao */ ' || chr(13);            	  
	  MyActionSql := MyActionSql || ' , null ';
      
	  --  num_cheque ***
      MyActionSql := MyActionSql ||     chr(13) || ' /* num_cheque */ ' || chr(13);            	  
	  MyActionSql := MyActionSql || ' , null ';                            
      
	  --  num_seq_credito_mensalidade
      MyActionSql := MyActionSql ||     chr(13) || ' /* num_seq_credito_mensalidade */ ' || chr(13);            	  
	  MyActionSql := MyActionSql || ' , ' || MySequencial;               
      
	  --  cod_usuario_log
	  MyActionSql := MyActionSql || ' , 1016283 ';                       
      
	  --  dt_atualiza_log
	  MyActionSql := MyActionSql || ' , ' || chr(39) || sysdate || chr(39);                         
      
	  --  txt_ip_log ***
	  MyActionSql := MyActionSql || ' , ' || chr(39) || MyIpLog || chr(39);                        
      
	  --  num_seq_inscricao
	  MyActionSql := MyActionSql || ' , null  ';                                                          
      
	  --  cod_usuario_acerto
	  MyActionSql := MyActionSql || ' , null  ';                           
      
	  --  dt_usuario_acerto
	  MyActionSql := MyActionSql || ' , null  ';                          
      
	  --  num_seq_ocorrencia
	  MyActionSql := MyActionSql || ' , null  ';                           
      
	  --  dt_cancelamento
	  MyActionSql := MyActionSql || ' , null  ';                           
      
	  --  cod_usuario_cancel
	  MyActionSql := MyActionSql || ' , null  ';                           
      
	  --  cod_rubrica_r3
	  MyActionSql := MyActionSql || ' , 179 ';                           
      
	  --  cod_usuario_inclusao
	  MyActionSql := MyActionSql || ' , ' || chr(39) || '93778848704' || chr(39) ;                   
      
	  --  dt_inclusao
	  MyActionSql := MyActionSql || ' , ' || chr(39) || sysdate || chr(39);                         
      
	  --  cod_concessionaria
	  MyActionSql := MyActionSql || ' , null   ';                          
      
	  --  cod_concessionaria_r3
	  MyActionSql := MyActionSql || ' , null   ';                         
      
	  --  id_instituicao_mig
	  MyActionSql := MyActionSql || ' , null   ';                         
      
	  --  cod_disciplina
	  MyActionSql := MyActionSql || ' , null   ';                          
      
	  --  ind_mov_disciplina
	  MyActionSql := MyActionSql || ' , null   ';                          
      
	  -- num_seq_debito_mensalidade 
	  MyActionSql := MyActionSql || ' , ' || cDM.num_seq_debito_mensalidade ;
      MyActionSql := MyActionSql || '  ); ' ;
            
      execute immediate MyActionSql;
                          
      commit;    
      
      dbms_output.put_line( MyActionSql );

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

    update SIA.debito_mensalidade deme
    set    deme.ind_situacao_debito = 3    
    where  deme.ind_situacao_debito = 1
    and    deme.num_seq_debito_mensalidade = cDM.num_seq_debito_mensalidade ;
      
    --commit;
    rollback;
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
    and    column_name = 'NUM_SEQ_DEBITO_ORIGEM'
    and    upper( table_name ) = 'CREDITO_MENSALIDADE'
    and    owner = 'SIA';
      
    if MyResult <> 1 then
      
      MyActionSql := 'alter table sia.credito_mensalidade add NUM_SEQ_DEBITO_ORIGEM number;';
      
      -- Erro -> operação de adição/eliminação não suportada em tabelas compactadas
	  -- Lazaro sugeriu que criassemos essa consulta no aplicar.sql da branch
      --dbms_output.put_line( MyActionSql );
      --execute immediate MyActionSql; 
            
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
