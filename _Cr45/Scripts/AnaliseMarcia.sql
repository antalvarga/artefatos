Nome do aluno : JOSILENE SODRE SOBRINHO


Matrícula do aluno : 201809117488

--
select ac.num_seq_aluno_curso , ac.num_seq_candidato
from sia.aluno_curso ac
where ac.cod_matricula  = '201809117488'
---1  4328628     6043752

-- Esta consulta filtra o carne antes da pessoa se tornar aluno => Vide nr candidato
select  car.dt_mes_ano_competencia , car.num_seq_carne , car.ind_tipo_carne , car.ind_situacao_carne  , car.* 
from sia.carne car 
where car.num_seq_candidato = 6043752 -- candidato
and   car.dt_mes_ano_competencia in ('01/07/2018','01/08/2018') 
--- 2     49,00    137440190
--- 9    339,55    138226625

--  *** D I S ***
select * 
from sia.acordo_especial_titulos aet
where aet.num_seq_carne = 137440190
-- result 0

select * 
from sia.acordo_especial_titulos aet
where aet.num_seq_carne = 138226625
-- 1093910

select * 
from sia.acordo_especial_titulos aet
where aet.num_seq_acordo_especial = 1093910

--- *** Diluição *** 
-- pegar o cod_rubrica_r3
select cm.* 
from sia.mensalidade men, 
     sia.composicao_mensalidade cm
where men.num_seq_carne =     137440190
and   men.num_seq_mensalidade = cm.num_seq_mensalidade  

-- 
select * from interface.sap_rubrica_r3 r3
where r3.cod_rubrica_r3 = 381
-- 381	DILUIÇÃO CONFIRMAÇÃO DA MATRÍCULA

select * 
from sia.tipo_bolsa tb
where tb.cod_rubrica_r3 = 381

-- composicao_mensalidade > bol.num_seq_bolsista donde ind_debito_credito = 'D'
select * 
from sia.bolsista bol
where bol.num_seq_bolsista = 31461997

-- NUM_SEQ_ALUNO_CURSO peguei da tabela sia.aluno_curso
select  car.dt_mes_ano_competencia , car.num_seq_carne , car.ind_tipo_carne , car.ind_situacao_carne  , car.* 
from sia.carne car 
where car.num_seq_aluno_curso = 4328628
and   car.dt_mes_ano_competencia in ('01/07/2018','01/08/2018') 
---- 6(vide licoesEstacio.txt)   49,00    138017695
---- 9(vide licoesEstacio.txt)  339,59   138231498

-- *** Aonde encontrou esse num_seq_carne ?
select cm.* 
from sia.mensalidade men, 
     sia.composicao_mensalidade cm 
where men.num_seq_carne =    138017695
and   men.num_seq_mensalidade = cm.num_seq_mensalidade  

-- 
select * 
from sia.acordo_especial_titulos aet
where aet.num_seq_carne = 138231498

-- 
select aet.* , 
       (select car.txt_nosso_numero 
       from sia.carne car 
       where car.num_seq_carne = aet.num_seq_carne
       ) txt_nosso_numero , 
       (select car.val_a_pagar 
       from sia.carne car 
       where car.num_seq_carne = aet.num_seq_carne
       ) val_a_pagar, 
       (select dm.txt_debito_mensalidade
       from sia.debito_mensalidade dm 
       where dm.num_seq_debito_mensalidade = aet.num_seq_debito_mensalidade
       ) txt_nosso_numero ,
       (select dm.val_a_receber
       from sia.debito_mensalidade dm 
       where dm.num_seq_debito_mensalidade = aet.num_seq_debito_mensalidade
       ) 
from sia.acordo_especial_titulos aet
where aet.num_seq_acordo_especial = 1088761


--
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
       )  valor_divida_nova, 
       ae.dt_acordo_especial , ae.num_seq_candidato , 
       (select ac.cod_matricula 
        from sia.aluno_curso ac
        where ac.num_seq_aluno_curso = ae.num_seq_aluno_curso
        ) cod_matricula 
from sia.acordo_especial ae, 
     sia.tipo_acordo_especial tp
where ae.ind_situacao = '8' 
and   ae.cod_tipo_acordo_especial = '4' 
and   ae.num_seq_acordo_especial = 1088761
and   ae.cod_tipo_acordo_especial = tp.cod_tipo_acordo_especial 
and   abs( (select car.val_a_pagar  
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
           )  
           ) > 0.01    



