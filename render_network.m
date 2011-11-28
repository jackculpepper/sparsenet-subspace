function array = render_network(A, Msz)

[L M] = size(A);

Lsz = sqrt(L);

buf = 1;

m = Msz;
n = M/Msz;

array = -ones(buf+m*(Lsz+buf),buf+n*(Lsz+buf));

k = 1;

for i = 1:m
    for j = 1:n
        clim = max(abs(A(:,k)));

        array(buf+(i-1)*(Lsz+buf)+[1:Lsz],buf+(j-1)*(Lsz+buf)+[1:Lsz]) = ...
            reshape(A(:,k),Lsz,Lsz)/clim;

        k = k+1;
    end
end

