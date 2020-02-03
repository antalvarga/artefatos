create or replace procedure sia.ProcTratativa(
                                                pNumeroAcordo in PLS_INTEGER
                                              )
is

-- declare


  -- Armazena as ocorrencias que houve na seleção  
  type v_Array is varray(4) of  char(1) ;
  MyOpera v_Array;
  
  MySum number;
  MyCount number;
  MyPoint number;
  MyAcordo number;
  MyReturn number;
  MyParam varchar2(500);
  ErrOracle varchar2(3700);


  /*
      Consulta atualizada pelo 
      e-mail Marcia Nepomuceno do Amaral <marcia.amaral.ter@estacio.br>
      em seg 03/02/2020 11:41
      Para Antal Varga  
  */
  -- 0- Para cada acordo listado :
  cursor cursorAcordo is
    select ae.num_seq_acordo_especial , ae.cod_tipo_acordo_especial, tp.nom_tipo_acordo_especial ,           
           (select car.val_a_pagar  
           from sia.carne car , 
                sia.acordo_especial_titulos aet 
           where aet.num_seq_acordo_especial = ae.num_seq_acordo_especial 
           and   aet.num_seq_carne = car.num_seq_carne 
           ) valor_divida_antiga ,
          (select sum( dm.val_a_receber ) 
           from sia.acordo_especial_titulos aet, 
                sia.debito_mensalidade dm 
           where aet.num_seq_debito_mensalidade = dm.num_seq_debito_mensalidade 
           and   aet.num_seq_acordo_especial = ae.num_seq_acordo_especial
           and   dm.ind_situacao_debito <> '3' 
           )  valor_divida_nova, 
           ae.dt_acordo_especial ,
            ae.num_seq_candidato , 
            (select sitc.nom_situacao_candidato 
            from sia.candidato cand, 
                 sia.situacao_candidato sitc
            where cand.cod_situacao_candidato = sitc.cod_situacao_candidato 
            and   cand.num_seq_candidato = ae.num_seq_candidato 
            ) situacao_candidato,      
           (select ac.cod_matricula 
            from sia.aluno_curso ac
            where ac.num_seq_aluno_curso = ae.num_seq_aluno_curso
            ) cod_matricula , 
            (select sit.nom_situacao_aluno  
            from sia.aluno_curso ac, 
                 sia.situacao_aluno_curso sit 
            where ac.num_seq_aluno_curso = ae.num_seq_aluno_curso
            and   ac.cod_situacao_aluno = sit.cod_situacao_aluno 
            ) situacao_aluno,
            
           (select sum(cm.val_restituicao) --- cm.num_seq_credito_mensalidade 
           from sia.credito_mensalidade cm 
           where cm.num_seq_candidato  = ae.num_seq_candidato
           and   cm.txt_credito_mensalidade = 'DEVOLUÇÃO POR PAGAMENTO DE PARCELA CANCELADA DO DIS COBRADA DE FORMA RETROATIVA'
           and   cm.cod_motivo_credito = '19'
           and   cm.ind_situacao_credito in ('1','2') 
           ) valor_tot_cred_candidato ,
            
           (select sum(cm.val_restituicao) --- cm.num_seq_credito_mensalidade 
           from sia.credito_mensalidade cm 
           where cm.num_seq_aluno_curso = ae.num_seq_aluno_curso 
           and   cm.txt_credito_mensalidade = 'DEVOLUÇÃO POR PAGAMENTO DE PARCELA CANCELADA DO DIS COBRADA DE FORMA RETROATIVA'
           and   cm.cod_motivo_credito = '19'
           and   cm.ind_situacao_credito in ('1','2') 
           ) valor_tot_cred_aluno
                     
    from sia.acordo_especial ae, 
         sia.tipo_acordo_especial tp
    where ae.ind_situacao = '8' 
    and   ae.cod_tipo_acordo_especial = '4' 
    ---and   ae.num_seq_acordo_especial = 1088761 ----------------exemplo 
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
    select dm.num_seq_debito_mensalidade , dm.dt_mes_ano_referencia , dm.val_a_receber , 
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
            ) valor_carne    ,
            dm.ind_situacao_debito  , 
            (select decode(car3.ind_situacao_carne , '1','pendente', '2','baixado', 'cancelado') 
            from sia.carne car3, 
                 sia.debito_credito_consumido dcc3
            where car3.num_seq_carne = dcc3.num_seq_carne 
            and   dcc3.num_seq_debito_mensalidade = dm.num_seq_debito_mensalidade
            )situacao_carne, 
            (select car3.val_pago 
            from sia.carne car3, 
                 sia.debito_credito_consumido dcc3
            where car3.num_seq_carne = dcc3.num_seq_carne 
            and   dcc3.num_seq_debito_mensalidade = dm.num_seq_debito_mensalidade
            ) valor_pago  ,
           (select tb.nom_tipo_baixa 
            from sia.carne car3, 
                 sia.debito_credito_consumido dcc3, 
                 sur.tipo_baixa tb 
            where car3.num_seq_carne = dcc3.num_seq_carne 
            and   dcc3.num_seq_debito_mensalidade = dm.num_seq_debito_mensalidade
            and   car3.ind_tipo_baixa = tb.cod_tipo_baixa 
            )  tipo_baixa,
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
    order by dm.num_seq_debito_mensalidade , dm.dt_mes_ano_referencia; 

  --
  cDM cursorDebitoMensalidade%Rowtype;
    

  function InserirCredito( pValorCredito in number 
                           , pOperacao   in varchar2 
--                           , MyCdm       in cursor
                           
                          ) return pls_integer
  --as
  is
    --MyReturn pls_integer;
    -- v_num_seq_cred_deb_consumido
    -- MySequencialCredito sia.debito_credito_consumido.num_seq_deb_cred_consum%type;
    MySequencial integer;
    MyIpLog varchar2(10);
    
  begin
    -- Not Implement
    --MyReturn := 0;
    MyPoint := 5;
    MyIpLog := cDM.Txt_Ip_Log;
    
    select sia.s_credito_mensalidade.nextval into MySequencial
    from   dual;
       
    
    /*
    select segu.txt_ip_log into MyIpLog
    from   segu.usuario segu
    where  segu.cod_usuario = cDM.**
    */

insert into credito_mensalidade
    ( 
      num_seq_periodo_academico
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
    )
    values 
    (                        
      cDM.Seqperiodo	             --  num_seq_periodo_academico
      , '9'             					--  cod_moeda
      , '19'            					--  cod_motivo_credito
      , 'DEVOLUÇÃO POR PAGAMENTO DE PARCELA CANCELADA DO DIS COBRADA DE FORMA RETROATIVA' --  txt_credito_mensalidade
      , cDM.dt_vencimento 				--  dt_vencimento
      , null          		            --  dt_restituicao
      , null                            --  val_restituido
      , null                            --  val_credito_extendido
      , '1'                             --  ind_situacao_credito
      , null                            --  ind_forma_restituicao
      , cDM.dt_mes_ano_referencia        --  dt_mes_ano_referencia
      , '1'                             --  ind_tipo_credito
      , cDM.num_seq_aluno_curso          --  num_seq_aluno_curso
      , cDM.val_a_receber                --  val_restituicao
      , null                            --  cod_curso ***
      , cDM.num_seq_grupo                --  num_seq_grupo
      , cDM.num_seq_candidato            --  num_seq_candidato
      , cDM.SeqTurmaExt --  num_seq_aluno_turma_extensao
      , null                            --  num_cheque ***
      , MySequencial                    --  num_seq_credito_mensalidade
      , '1016283'                       --  cod_usuario_log
      , sysdate                         --  dt_atualiza_log
      , MyIpLog                         --  txt_ip_log ***
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
    );
      
    commit;
    --MyReturn := 1;
    return 1;
  
  exception
    when others then
      --rollback;
      return 0;
  
  end; -- InserirCredito;
  --  

begin

/*
  for MyCount in 1..MyOpera.count loop
    MyOpera( MyCount ) := 0;
  end loop;
*/
  if pNumeroAcordo is not null then
    MyAcordo := pNumeroAcordo;

  end if;
    
/*
0 - Para cada acordo listado :

1 - selecionar todos os débitos mensalidade do acordo com  dm.ind_situacao_debito <> '3'

orderndos pelos campos dm.num_seq_debito_mensal , dm.dt_mes_ano_referencia


2 - Quando o somatório dos val_a_receber > valor_carne , para cada débito verificar:

2.1 Lançar um crédito no valor total dos débitos para os débitos consumidos em carne baixado com valor pago > 0 ,(débitos com situacao = 2)

2.2 Lançar um crédito no valor do débito para cada débito consumido em carne com situacao carne = pendente, ou seja,
para cada débito lançar um crédito nessa situação. (débitos com situacao = 2)

2.3 Como procedecer com os débitos consumidos em carne baixado sem valor pago ??? (débitos com situacao = 2)

2.4 Cancelar os débitos não consumidos, ind_situacao_debito =1, ou mudar a situacao de 1 para 3.


*/

  MyPoint := 1;
  MyParam := '';
  MyCount := 0;
  
  for item in cursorAcordo loop
    MyAcordo := item.num_seq_acordo_especial;

    dbms_output.put_line( MyAcordo );

    MySum := 0;    
    MyPoint := 2;

    for MyCount in 1..MyOpera.count loop
      MyOpera( MyCount ) := 0;
    end loop;
    
    
    -- Abrir cursor Num_Seq_Debito_Mensalidade
    open cursorDebitoMensalidade( MyAcordo );
    loop
      exit when cursorDebitoMensalidade%notfound;

      fetch cursorDebitoMensalidade into cDM;
      
      MySum := MySum + cDM.Val_a_Receber;

      -- 2 - Quando o somatório dos val_a_receber > valor_carne , para cada débito verificar:
      if MySum > item.valor_divida_antiga then
        
        dbms_output.put_line( cDM.Num_Seq_Debito_Mensalidade );
                
        /*
        Sequencial na function
        -- Recuperar sequencial para geração do credito
        select sia.s_debito_credito_consumido.nextval
          into MySequencialCredito
          from dual;
        -- Montar MyParam
       */

        -- ***

        -- 2.1 Lançar um crédito no valor total dos débitos para os débitos consumidos em carne baixado com valor pago > 0 ,(débitos com situacao = 2)
        if cDM.Situacao_Carne = 'baixado' and cDM.Valor_Pago > 0 then          
          
          MyOpera(1) := 1;
          dbms_output.put_line( '2.1 = ' || cDM.Num_Seq_Debito_Mensalidade);
                              
        end if;  
          
        -- 2.2 Lançar um crédito no valor do débito para cada débito consumido em carne com situacao carne = pendente, ou seja,
        -- para cada débito lançar um crédito nessa situação. (débitos com situacao = 2)
        if cDM.Situacao_Carne = 'pendente' and cDM.Ind_Situacao_Debito = 2  then

          MyOpera(2) := 1; 
          dbms_output.put_line( '2.2 = ' || cDM.Num_Seq_Debito_Mensalidade);
          
          MyReturn := InserirCredito( cDM.Val_a_Receber
                                       , '2.2'
                      --                 , cDM   
                                     );
          
        end if;
          
        -- 2.3 Como procedecer com os débitos consumidos em carne baixado sem valor pago ??? (débitos com situacao = 2)
        if cDM.Ind_Situacao_Debito = 2 and cDM.Situacao_Carne = 'baixado' and cDM.Valor_Pago =0 then

          MyOpera(3) := 1; 
          dbms_output.put_line( '2.3 = ' || cDM.Num_Seq_Debito_Mensalidade);
          
        end if; 

        -- 2.4 Cancelar os débitos não consumidos, ind_situacao_debito = 1, ou mudar a situacao de 1 para 3.
        if cDM.Ind_Situacao_Debito = 1 then

          MyOpera(4) := 1;
          dbms_output.put_line( '2.4 = ' || cDM.Num_Seq_Debito_Mensalidade);
          
        end if;
        
      end if;

    end loop;

    -- -- 2.1 Lançar um crédito no valor total dos débitos...
    if MyOpera(1) = 1 then
      MyReturn := InserirCredito( MySum , '2.1' );      
      dbms_output.put_line( '2.1' );
            
    end if ;
    
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
