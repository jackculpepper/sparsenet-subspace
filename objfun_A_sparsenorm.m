function [f,g] = objfun_A_sparsenorm(x0,s,I,lambda,K);

L = size(I,1);
M = size(s,1);
batch_size = size(I,2);
A = reshape(x0,L,M);

EI = A*s;

R = I - EI;

s_sub = reshape(s, K, M/K, batch_size);

As = zeros(L, M, batch_size);
for m = 1:M
    As(:,m,:) = A(:,m) * s(m,:);
end
As = reshape(As, L, K, M/K, batch_size);

Q = sum(As, 2);
%O = sum(Q.^2, 1);

As_mag = sqrt(sum(Q.^2, 1));

f_residual = 0.5 * sum(R(:).^2) / batch_size;
f_sparse = lambda * sum(As_mag(:)) / batch_size;

f = f_residual + f_sparse;


if nargout > 1

    df_residual = -R*s'/batch_size;


    if 0
        for k = 1:K
            df_sparse(k,:,:) = 1 ./ shiftdim(As_mag(1,1,:,:),1) .* P(k,:,:);
        end
    else
        %As_mag = shiftdim(As_mag,1);
        s_sub = shiftdim(s_sub, -1);
        df_sparse = mean( s_sub(ones(1,L), :, :, :) .* ...
                          Q(:,ones(1,K),:,:) ./ ...
                          As_mag(ones(1,L), ones(1,K), :, :), 4);
    end


    df = df_residual + lambda * reshape(df_sparse, L, M);

    g = df(:);
end

