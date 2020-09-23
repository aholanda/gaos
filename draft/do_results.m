function M = do_results(which_experiment, do_sk_test)
%%
% do_results run plfit(), plpva() and plfit() function on degree data
% generated stored, one per line, in csv files, and write the output to a
% TeX file.
%
% which_experiment - string that can receive two possible values, 
%                    'kernel' or 'subsys'. The first fits the distribution
%                    degrees, calculates the power law coefficient and
%                    plot the curve for kernel subsystem from the first
%                    up to the latest Linux release. 'subsys' argument 
%                    process Linux subsystems for the latest release.
%
% do_sk_test -       boolean value indicating if plpva()
%                    (Kolmogorov-Smirnoff test) function must be run.
%                    The function takes few minutes to run and sometimes,
%                    we need only plot the curves, so set this parameter to
%                    zero.
%
% Dependencies: plfit.m, plpva.m, plplotk.m
%
%
% Examples: do_results('kernel', 1); % run for kernel, do Kolmogorov-Smirnoff test
%           do_results('subsys', 0); % run for subsys, don't do Kolmogorov-Smirnoff test 
%%
    % latest version of the kernel
    latest_version = '4.14.14'

    switch which_experiment

        case 'kernel',
    
            vers = {'1.0',  '1.1.95',  '1.2.13', '1.3.100', '2.1.132', '2.2.26', '2.3.99-pre9', '2.4.37.11', '2.5.75', '2.6.39', '3.19.8', latest_version};
            idx = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
            vers2idx = containers.Map(vers, idx);

            vers_vec = keys(vers2idx);
            idx_vec = values(vers2idx);

            % vectors to store results, sequence is first in and then out
            alphas_in = [];
            alphas_out = [];
            xmins_in = [];
            xmins_out = [];
            xmaxs_in = [];     
            xmaxs_out = [];
            ps_in = [];
            ps_out = [];

            N=length(vers2idx);
            %N=1
            for n = 1:N
                ver = vers_vec{n};
                name = strcat('linux-', ver);
                name = strcat(name, '-kernel');
                suf = strcat('deg-vals-', strcat(name, '.csv'));
                fn = strcat('in', suf);
                disp(fn);
                x_in = csvread(fn);
                [alpha_in, xmin_in, L_in] = plfit(x_in);
                
                p_in = 0.0
                if do_sk_test
                    p_in = plpva(x_in, xmin_in); 
                end

                xmins_in = [xmins_in, xmin_in];
                alphas_in = [alphas_in, alpha_in];
                ps_in= [ps_in, p_in];

                fn = strcat('out', suf);
                x_out = csvread(fn);
                [alpha_out, xmin_out, L_out] = plfit(x_out);
                
                p_out = 0.0
                if do_sk_test
                    p_out = plpva(x_out, xmin_out);
                end

                xmins_out = [xmins_out, xmin_out];
                alphas_out = [alphas_out, alpha_out];
                ps_out = [ps_out, p_out];

                h = plplotk(x_in, xmin_in, alpha_in, x_out, xmin_out, alpha_out, name, which_experiment, n);

                % to use in the statistics
                xmax_in = max(x_in); 
                xmax_out = max(x_out); 

                xmaxs_in = [xmaxs_in, xmax_in];
                xmaxs_out = [xmaxs_out, xmax_out];    
            end
                        
            M = [alphas_in; alphas_out; xmins_in; xmins_out; xmaxs_in; xmaxs_out; ps_in; ps_out];
            
            % Make send write the results only if there were changes in the
            % data, this is marked by do_sk_test.
            if do_sk_test
                write_results(vers, M, 'table1.tex', which_experiment);
            end                     
  
          case 'subsys',
        
            % ignoring IPC due low quantity of data
            subs = {'block',  'drivers','fs', 'mm', 'net', 'sound'};
            idx = [1, 2, 3, 4, 5, 6];
            vers2idx = containers.Map(subs, idx);

            subs_vec = keys(vers2idx);
            idx_vec = values(vers2idx);

            % vectors to store results, sequence is first in and then out
            alphas_in = [];
            alphas_out = [];
            xmins_in = [];
            xmins_out = [];
            xmaxs_in = [];
            xmaxs_out = [];
            ps_in = [];
            ps_out = [];

            N=length(vers2idx)
            %N=1  % for debug purposes
            for n = 1:N
                ss = subs_vec{n};
                name = strcat('linux-', latest_version);
                name = strcat(name, '-');  
                name = strcat(name, ss);
                suf = strcat('deg-vals-', strcat(name, '.csv'));
                fn = strcat('in', suf);
                disp(fn);
                x_in = csvread(fn);
                [alpha_in, xmin_in, L_in] = plfit(x_in)
                
                p_in = 0.0
                if do_sk_test
                    p_in = plpva(x_in, xmin_in); 
                end

                xmins_in = [xmins_in, xmin_in];
                alphas_in = [alphas_in, alpha_in];
                ps_in= [ps_in, p_in];

                fn = strcat('out', suf);
                x_out = csvread(fn);
                [alpha_out, xmin_out, L_out] = plfit(x_out)
                
                p_out = 0.0
                if do_sk_test
                    p_out = plpva(x_out, xmin_out);
                end

                xmins_out = [xmins_out, xmin_out];
                alphas_out = [alphas_out, alpha_out];
                ps_out = [ps_out, p_out];

                h = plplotk(x_in, xmin_in, alpha_in, x_out, xmin_out, alpha_out, name, which_experiment, n);

                % to use in the statistics
                xmax_in = max(x_in); 
                xmax_out = max(x_out); 

                xmaxs_in = [xmaxs_in, xmax_in];
                xmaxs_out = [xmaxs_out, xmax_out];    
            end
            
            M = [alphas_in; alphas_out; xmins_in; xmins_out; xmaxs_in; xmaxs_out; ps_in; ps_out];  
            
            % Make send write the results only if there were changes in the
            % data, this is marked by do_sk_test.
            if do_sk_test
                write_results(subs, M, 'table2.tex', which_experiment);
            end                     
            
        otherwise,
    
            fprintf('Please choose kernel or subsys for which_experiment parameter');
            M = [];
            return;    
            
    end
        
end