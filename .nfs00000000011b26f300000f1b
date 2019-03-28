--Building complete landtenure dataset
INSERT INTO lt_model.v_pacotes_proc05_imoveisfull
    SELECT * FROM lt_model.v_pacotes_proc03_unregistered AS a
    UNION ALL
    SELECT * FROM lt_model.v_pacotes_proc04_flagprop AS b;