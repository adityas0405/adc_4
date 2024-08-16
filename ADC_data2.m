

%IMPORTING DATAT FROM CSV FILE
data = importdata("dts_data2.csv");

%Assigning and extracting numerical values from the structure
TEMP = data.data(:,1);
VPTAT = data.data(:,2);
VCTAT = data.data(:,3);

%ASSIGNING NECESSARY VALUES FOR SIMULATION
vos = 10e-3;
Fs = 1e+06;
a = 4.32;
DF = 2048; %WILL VARY 64-8192 (2^x @ conversion type)
vn = 10e-6;

%CREATING DATA STORAGE
Filter_output = zeros(length(TEMP),1);
Filter_output_mean = zeros(length(TEMP),1);

%THIS FIRST PART WILL JUST TAKE dts_data2 DATA AND TURN RETURN THE MEAN (AFTER ADC) AND
%ADC COUNT (AFTER CIC DECIMATION)
%FOR LOOP TO RUN THOUGH ALL THE VALUES INTO THE ADC
for i = 1:1:length(TEMP)
    i
    temp = TEMP(i);
    T = temp + 273.15; %Won't save change to kelvins in table as the python file already does this
    vctat = -VCTAT(i);
    vptat = VPTAT(i);
    simout = sim('dts_adc1');
    Filter_output([i]) = dts_out.Data(length(dts_out.Data));
    Filter_output_mean([i]) = dts_outmean.Data(length(dts_outmean.Data));
end
ADC_filter_data = [TEMP, Filter_output, Filter_output_mean]
col_labels = ["Temperature" "ADC count" "Mean"];
ADC_filter_data = array2table(ADC_filter_data, "VariableNames",col_labels);
save("ADC_filter_data");


%saving as csv file
writetable(ADC_filter_data,'dts_adc_output.csv')
%created seperate ADC count file to run in python script
writetable([ADC_filter_data(:,1), ADC_filter_data(:,2)],'dts_adc_ADC_count.xlsx')
movefile('dts_adc_ADC_count.xlsx','C:\Users\adity\Desktop\adc_4'); %C:\Users\adity\Desktop\adc_4
%C:\Users\SinhaAd\Desktop\ADC\4_o\adc_4
%IF THE LOCATION OF THE PYTHON FILE IS DIFFERENT FROM HEN CHANGE TO
%CORRECT LOCATION
%END OF FIRTS PART

%SECOND PART OF SCRIPT IS LOOKING FOR SNR FOR DIFFERENT DECIMATION FACTOR at 45 degrees Celcius
V = rot90(dts_out.Data(2:1:length(dts_out.Data)))
sigma = STD(V)

SIGMA_VPTAT = (vptat-vctat)*(sigma/((DF/2)^2))
SNR = 20*log10((vptat)/((2^(1/2))*SIGMA_VPTAT))
ADC_mean = DataSelectionBasedOfTime(dts_out.Time,[dts_outmean.Time,dts_outmean.Data])
noise_voltage = SNR*slope(dts_out.Data, ADC_mean)


%standard deviation function
function result_holder = STD(array)
    mean = sum(array)/length(array);
    summing = zeros(length(array),1);
    for i = 1:1:length(array)
        summing(i) = (array(i) - mean)^2;
    end
    total_summing = sum(summing);

    result_holder = (total_summing/length(array))^(1/2);
end

%slope function
function slope = slope(x,y)
    lower = randi([1, round(length(x)/2)])
    upper = randi([round(length(x)/2)+1, length(x)])

    while upper < lower+5
        upper = randi([round(length(x)/2)+1, length(x)])
    end
    y_lower = y(lower)
    y_upper = y(upper)
    x_lower = x(lower)
    x_upper = x(upper)

    yt = y(upper) - y(lower)
    xt = x(upper) - x(lower)
    slope = (y(upper) - y(lower))/(x(upper) - x(lower))
end

%data specifier based on time
function DownSample = DataSelectionBasedOfTime(DesiredTimePoints, OversampledData)
    GivenData = OversampledData(:,2);
    GivenTime = OversampledData(:,1);
    DownSample = zeros(length(DesiredTimePoints),1);
    for runner = 1:1:length(DesiredTimePoints)
        for finder = 1:1:length(GivenTime)
            if DesiredTimePoints(runner) == GivenTime(finder)
                DownSample(runner) = GivenData(finder);
                GivenTime = GivenTime(finder:length(GivenTime));
                GivenData = GivenData(finder:length(GivenData));
                break
            end
            runner
        end
    end
    DownSample
end
