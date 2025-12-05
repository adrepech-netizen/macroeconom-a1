<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Modelo IS-LM Interactivo</title>
    <script src="https://cdn.plot.ly/plotly-2.24.1.min.js"></script>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f4f4f9; color: #333; }
        
        header { background-color: #2c3e50; color: white; padding: 15px; text-align: center; }
        h1 { margin: 0; font-size: 1.5rem; }
        .credits { font-size: 0.9rem; margin-top: 5px; color: #ecf0f1; }
        
        /* Contenedor principal */
        .container { 
            display: flex; 
            flex-wrap: wrap; 
            padding: 10px; 
            align-items: flex-start; /* Importante para que sticky funcione */
        }
        
        /* --- CAMBIOS PRINCIPALES AQUÍ --- */
        /* Panel de Controles "Pegajoso" */
        .controls { 
            flex: 1; 
            min-width: 300px; 
            background: white; 
            padding: 20px; 
            border-radius: 8px; 
            box-shadow: 0 4px 8px rgba(0,0,0,0.15); 
            margin-right: 20px; 
            margin-bottom: 10px;
            
            /* Hacemos que el panel se pegue */
            position: -webkit-sticky; /* Para Safari */
            position: sticky;
            top: 20px; /* Se queda a 20px del borde superior */
            
            /* Si la pantalla es baja, permitimos scroll dentro del panel */
            max-height: calc(100vh - 40px);
            overflow-y: auto;
            z-index: 1000;
        }

        .control-group { margin-bottom: 15px; border-bottom: 1px solid #eee; padding-bottom: 10px; }
        .control-group:last-child { border-bottom: none; }
        
        label { display: block; margin-bottom: 5px; font-weight: bold; font-size: 0.9rem; }
        input[type=range] { width: 100%; cursor: pointer; }
        .val-display { float: right; color: #007bff; font-family: monospace; }

        /* Panel de Gráficos */
        .charts-area { flex: 3; display: flex; flex-wrap: wrap; gap: 15px; }
        .chart-box { background: white; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); padding: 5px; flex: 1 1 45%; min-width: 300px; height: 350px; }
        .full-width { flex: 1 1 100%; height: 450px; }

        /* Responsividad para móviles */
        @media (max-width: 768px) {
            .container { flex-direction: column; padding: 0; }
            
            .controls { 
                width: 100%; /* Ocupa todo el ancho */
                box-sizing: border-box; /* Asegura que el padding no rompa el ancho */
                margin-right: 0;
                margin-bottom: 20px;
                border-radius: 0 0 10px 10px; /* Redondear solo abajo */
                
                /* Ajuste Sticky para Móvil */
                top: 0;
                max-height: 35vh; /* Ocupa máximo el 35% de la pantalla vertical */
                overflow-y: scroll; /* Scroll obligatorio si hay muchos controles */
                box-shadow: 0 5px 10px rgba(0,0,0,0.2);
                border-top: 1px solid #ccc;
            }

            .chart-box { width: 100%; min-width: auto; margin: 5px; }
            .full-width { height: 350px; }
            
            /* Título más pequeño en móvil */
            h1 { font-size: 1.2rem; }
        }
    </style>
</head>
<body>

<header>
    <h1>Modelo IS-LM Básico Interactivo</h1>
    <div class="credits">
        Autor: Dr. Adrián Eduardo Pech Quijano <br>
        Coautora: Dra. Ileana Mercedes Canepa Pérez
    </div>
</header>

<div class="container">
    <div class="controls">
        <h3>Parámetros</h3>
        <p style="font-size:0.8rem; color:#666; margin-top:0;">Desliza para ver cambios en tiempo real.</p>
        
        <div class="control-group">
            <label>Gasto Gobierno (G) <span id="val-G" class="val-display">200</span></label>
            <input type="range" id="slider-G" min="50" max="500" step="10" value="200">
        </div>

        <div class="control-group">
            <label>Impuestos (T) <span id="val-T" class="val-display">150</span></label>
            <input type="range" id="slider-T" min="50" max="400" step="10" value="150">
        </div>

        <div class="control-group">
            <label>Oferta Monetaria (M) <span id="val-M" class="val-display">400</span></label>
            <input type="range" id="slider-M" min="100" max="800" step="20" value="400">
        </div>

        <div class="control-group">
            <label>Propensión Consumo (c) <span id="val-c" class="val-display">0.8</span></label>
            <input type="range" id="slider-c" min="0.4" max="0.95" step="0.05" value="0.8">
        </div>
        
        <div class="control-group">
            <label>Sensibilidad Inv. (b) <span id="val-b" class="val-display">20</span></label>
            <input type="range" id="slider-b" min="5" max="50" step="1" value="20">
        </div>

        <div class="control-group">
            <label>Consumo Autónomo (Co) <span id="val-Co" class="val-display">100</span></label>
            <input type="range" id="slider-Co" min="50" max="300" step="10" value="100">
        </div>

         <div class="control-group">
            <label>Inversión Autónoma (Io) <span id="val-Io" class="val-display">150</span></label>
            <input type="range" id="slider-Io" min="50" max="300" step="10" value="150">
        </div>
    </div>

    <div class="charts-area">
        <div id="chart-islm" class="chart-box full-width"></div>
        <div id="chart-consumo" class="chart-box"></div>
        <div id="chart-inversion" class="chart-box"></div>
        <div id="chart-gasto" class="chart-box"></div>
        <div id="chart-cross" class="chart-box"></div>
    </div>
</div>

<script>
    // Variables Globales
    let G = 200, T = 150, M = 400, P = 2; 
    let c = 0.8; // Propensión marginal a consumir
    let b = 20;  // Sensibilidad de la inversión al interés
    let k = 0.5; // Sensibilidad demanda dinero a ingreso
    let h = 30;  // Sensibilidad demanda dinero a interés
    let Co = 100; // Consumo autónomo
    let Io = 150; // Inversión autónoma

    function updateDisplays() {
        document.getElementById('val-G').innerText = G;
        document.getElementById('val-T').innerText = T;
        document.getElementById('val-M').innerText = M;
        document.getElementById('val-c').innerText = c;
        document.getElementById('val-b').innerText = b;
        document.getElementById('val-Co').innerText = Co;
        document.getElementById('val-Io').innerText = Io;
    }

    function calculateData() {
        let yValues = [];
        for (let i = 0; i <= 2000; i+=50) yValues.push(i);

        // IS: r = (A/b) - ((1-c)/b)Y
        let is_rValues = yValues.map(Y => {
            let A = Co - (c * T) + Io + G; 
            return (A / b) - ((1 - c) / b) * Y;
        });

        // LM: r = (k/h)Y - (1/h)(M/P)
        let lm_rValues = yValues.map(Y => {
            let realMoney = M / P;
            return (k / h) * Y - (1 / h) * realMoney;
        });

        // Equilibrio
        let A = Co - (c * T) + Io + G;
        let realM = M / P;
        let numerator = h * A + b * realM;
        let denominator = h * (1 - c) + b * k;
        let eq_Y = numerator / denominator;
        let eq_r = (k / h) * eq_Y - (1 / h) * realM;

        return { yValues, is_rValues, lm_rValues, eq_Y, eq_r, A };
    }

    function calculateSubPlots(eq_Y, eq_r, A) {
        let rangeY = [];
        for (let i = 0; i <= eq_Y * 1.5; i+=eq_Y/20) rangeY.push(i);
        
        let C_values = rangeY.map(Y => Co + c * (Y - T));

        let rangeR = [];
        for (let i = 0; i <= eq_r * 2 + 5; i+=0.5) if(i>=0) rangeR.push(i);
        let I_values = rangeR.map(r => Io - b * r);

        let G_values = rangeY.map(() => G);

        let DA_values = rangeY.map(Y => (Co - c*T + Io - b*eq_r + G) + c*Y);
        let Y_Ref_values = rangeY;

        return { rangeY, C_values, rangeR, I_values, G_values, DA_values, Y_Ref_values };
    }

    // Configuración común para gráficos (Layout)
    const commonLayout = {
        margin: {t: 30, b: 30, l: 40, r: 10},
        autosize: true
    };

    function plotCharts() {
        let data = calculateData();
        let subData = calculateSubPlots(data.eq_Y, data.eq_r, data.A);

        // 1. IS-LM
        let traceIS = { x: data.yValues, y: data.is_rValues, mode: 'lines', name: 'IS', line: {color: 'blue'} };
        let traceLM = { x: data.yValues, y: data.lm_rValues, mode: 'lines', name: 'LM', line: {color: 'red'} };
        let traceEq = { x: [data.eq_Y], y: [data.eq_r], mode: 'markers', name: 'Eq', marker: {color: 'black', size: 10} };
        
        let layoutISLM = {...commonLayout, title: 'Equilibrio IS-LM', xaxis: {title: 'Y', range: [0, 2000]}, yaxis: {title: 'r', range: [0, 20]}, showlegend: true, legend: {x: 1, y: 1}};

        // 2. Consumo
        let traceC = { x: subData.rangeY, y: subData.C_values, mode: 'lines', name: 'C', line: {color: 'green'} };
        let layoutC = {...commonLayout, title: 'Consumo (C vs Y)', xaxis: {title: 'Y'}, yaxis: {title: 'C'}};

        // 3. Inversión
        let traceI = { x: subData.I_values, y: subData.rangeR, mode: 'lines', name: 'I', line: {color: 'purple'} };
        let layoutI = {...commonLayout, title: 'Inversión (I vs r)', xaxis: {title: 'I'}, yaxis: {title: 'r'}};

        // 4. Gasto
        let traceG = { x: subData.rangeY, y: subData.G_values, mode: 'lines', name: 'G', line: {color: 'orange', width: 3} };
        let layoutG = {...commonLayout, title: 'Gasto Gobierno (G)', xaxis: {title: 'Y'}, yaxis: {title: 'G', range: [0, 600]}};

        // 5. Cruz Keynesiana
        let trace45 = { x: subData.rangeY, y: subData.Y_Ref_values, mode: 'lines', name: '45°', line: {color: 'gray', dash: 'dash'} };
        let traceDA = { x: subData.rangeY, y: subData.DA_values, mode: 'lines', name: 'DA', line: {color: 'blue'} };
        let layoutCross = {...commonLayout, title: 'Cruz Keynesiana (Y=DA)', xaxis: {title: 'Y'}, yaxis: {title: 'DA'}};

        Plotly.react('chart-islm', [traceIS, traceLM, traceEq], layoutISLM, {responsive: true});
        Plotly.react('chart-consumo', [traceC], layoutC, {responsive: true});
        Plotly.react('chart-inversion', [traceI], layoutI, {responsive: true});
        Plotly.react('chart-gasto', [traceG], layoutG, {responsive: true});
        Plotly.react('chart-cross', [trace45, traceDA], layoutCross, {responsive: true});
    }

    // Listeners
    let sliders = ['G', 'T', 'M', 'c', 'b', 'Co', 'Io'];
    sliders.forEach(id => {
        document.getElementById('slider-'+id).addEventListener('input', function(e) {
            if(id === 'G') G = parseFloat(e.target.value);
            if(id === 'T') T = parseFloat(e.target.value);
            if(id === 'M') M = parseFloat(e.target.value);
            if(id === 'c') c = parseFloat(e.target.value);
            if(id === 'b') b = parseFloat(e.target.value);
            if(id === 'Co') Co = parseFloat(e.target.value);
            if(id === 'Io') Io = parseFloat(e.target.value);
            updateDisplays();
            plotCharts();
        });
    });

    updateDisplays();
    plotCharts();
</script>

</body>
</html>
