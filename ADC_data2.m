% IMPORTING DATA FROM CSV FILE
data = importdata("dts_data2.csv");

% Assigning and extracting numerical values from the structure
TEMP = data.data(:,1);
VPTAT = data.data(:,2);
VCTAT = data.data(:,3);

% ASSIGNING NECESSARY VALUES FOR SIMULATION
vos = 5e-3;
Fs = 1e+06;
a = 4.32;
DF = 2048; % WILL VARY 64-8192 (2^x @ conversion type)
vn = 10e-6;

% CREATING DATA STORAGE
Filter_output = zeros(length(TEMP),1);
Filter_output_mean = zeros(length(TEMP),1);

% FOR LOOP TO RUN THROUGH ALL THE VALUES INTO THE ADC
for i = 1:1:length(TEMP)
    temp = TEMP(i);
    T = temp + 273.15; % Won't save change to kelvins in table as the python file already does this
    vctat = -VCTAT(i);
    vptat = VPTAT(i);
    simout = sim('dts_adc1');
    Filter_output(i) = dts_out.Data(end);  % Using 'end' to get the last element
    Filter_output_mean(i) = dts_outmean.Data(end);  % Using 'end' to get the last element
end

% Storing the ADC filter data in a table
ADC_filter_data = [TEMP, Filter_output, Filter_output_mean];
col_labels = ["Temperature", "ADC count", "Mean"];
ADC_filter_data = array2table(ADC_filter_data, "VariableNames", col_labels);
save("ADC_filter_data");

% Saving as csv file
writetable(ADC_filter_data,'dts_adc_output.csv');

% Creating separate ADC count file to run in Python script
writetable([ADC_filter_data(:,1), ADC_filter_data(:,2)], 'dts_adc_ADC_count.xlsx');
movefile('dts_adc_ADC_count.xlsx', 'C:\Users\adity\Desktop\adc_4'); 

% SECOND PART OF SCRIPT IS LOOKING FOR SNR FOR DIFFERENT DECIMATION FACTOR at 45 degrees Celsius
V = rot90(dts_out.Data(2:end));
sigma = STD(V);

SIGMA_VPTAT = (vptat - vctat) * (sigma / ((DF/2)^2));
SNR = 20 * log10((vptat) / (sqrt(2) * SIGMA_VPTAT));
ADC_mean = DataSelectionBasedOfTime(dts_out.Time, [dts_outmean.Time, dts_outmean.Data]);

% Calculate noise_voltage and slope
noise_voltage = SNR * slope(dts_out.Data, ADC_mean);

% Calculate and save the final slope value
final_slope = slope(dts_out.Data, ADC_mean);
disp(['Final slope value: ', num2str(final_slope)]); % Displaying the final slope value

% Saving the slope value to a .mat file in the current directory
save('final_slope_value.mat', 'final_slope');
final_slope  % This will display the value in the command window and workspace

% STANDARD DEVIATION FUNCTION
function result_holder = STD(array)
    mean_value = sum(array) / length(array);
    summing = zeros(length(array), 1);
    for i = 1:length(array)
        summing(i) = (array(i) - mean_value)^2;
    end
    total_summing = sum(summing);
    result_holder = sqrt(total_summing / length(array));
end

% SLOPE FUNCTION
function slope_value = slope(x, y)
    lower = randi([1, round(length(x)/2)]);
    upper = randi([round(length(x)/2) + 1, length(x)]);

    while upper < lower + 5
        upper = randi([round(length(x)/2) + 1, length(x)]);
    end

    yt = y(upper) - y(lower);
    xt = x(upper) - x(lower);
    slope_value = yt / xt;
end

% DATA SPECIFIER BASED ON TIME
function DownSample = DataSelectionBasedOfTime(DesiredTimePoints, OversampledData)
    GivenData = OversampledData(:, 2);
    GivenTime = OversampledData(:, 1);
    DownSample = zeros(length(DesiredTimePoints), 1);
    for runner = 1:length(DesiredTimePoints)
        for finder = 1:length(GivenTime)
            if DesiredTimePoints(runner) == GivenTime(finder)
                DownSample(runner) = GivenData(finder);
                GivenTime = GivenTime(finder:end);
                GivenData = GivenData(finder:end);
                break;
            end
        end
    end
end
