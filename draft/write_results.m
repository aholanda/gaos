function [] = write_results(labels, R, filename, which_experiment)
%%
% Write results to a file.
%
% labels -   vector with the labels.
% R -        matrix with results.
% filename - name of the file to write.
%
% Matrix of results has the form:
%
%             ( alpha_min ...   )
%             ( alpha_max ...   )
%             ( xmin_in   ...   )
%             ( xmin_out  ...   )
%   R =       ( xmax_in   ...   )
%             ( xmax_out  ...   )
%             ( alpha_in  ...   )
%             ( alpha_out ...   )
%
%%
label_title = '';
if which_experiment == 'kernel'
    label_title = 'version';
else
    label_title = 'subsystem';
end

% Write results to a file to be input in preprint.
f = fopen(filename, 'w');
fprintf(f, '\\begin{tabular}{c|cccc|cccc} \\hline\n');
fprintf(f, '%s & $\\alpha^{\\leftarrow}$ & $x_{min}^{\\leftarrow}$ & $x_{max}^{\\leftarrow}$ & $p^\\leftarrow$ & $\\alpha^{\\rightarrow}$ & $x_{min}^{\\rightarrow}$ & $x_{max}^{\\rightarrow}$ & $p^\\rightarrow$ \\\\ \\hline \n', label_title);
N=length(labels)
for n = 1:N       
    fprintf(f, '%s & %1.2f & %d & %d & %1.2f & %1.2f & %d & %d & %1.2f \\\\ \n', labels{n}, R(1,n), R(3,n), R(5,n), R(7,n), R(2,n), R(4,n), R(6,n), R(8,n));         
end
    fprintf(f, '\\end{tabular}\n');
    fclose(f);
end