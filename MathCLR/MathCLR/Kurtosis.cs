using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.IO;
using System.Collections;
using System.Collections.Generic;


[Serializable]
[Microsoft.SqlServer.Server.SqlUserDefinedAggregate(Format.UserDefined, IsInvariantToDuplicates = false, IsInvariantToNulls = false, IsNullIfEmpty = true, IsInvariantToOrder = true, MaxByteSize = -1)]
public struct Kurtosis : Microsoft.SqlServer.Server.IBinarySerialize
{
    //Based on the psuedocode from http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Higher-order_statistics
    public void Init()
    {
        // Put your code here
        this.n = 0;
        this.mean = Convert.ToDecimal(0.0);
        this.m2 = Convert.ToDecimal(0.0);
        this.m3 = Convert.ToDecimal(0.0);
        this.m4 = Convert.ToDecimal(0.0);
    }

    public void Accumulate(SqlDouble FirstValue)
    {
        // Put your code here
        if (FirstValue.IsNull != true)
        {
            int n1 = this.n;
            this.n++;
            decimal delta = Convert.ToDecimal(FirstValue.Value) - this.mean;
            decimal delta_n = delta / Convert.ToDecimal(this.n);
            decimal delta_n2 = delta_n * delta_n;
            decimal term1 = delta * delta_n * Convert.ToDecimal(n1);
            this.mean += delta_n;
            if (n1 > 0)
            {
                this.m4 += term1 * delta_n2 * 
                    ( Convert.ToDecimal(n*n) - Convert.ToDecimal(3 * this.n) + Convert.ToDecimal(3) )
                    + Convert.ToDecimal(6) * delta_n2 * this.m2
                    - Convert.ToDecimal(4) * delta_n * this.m3;
                this.m3 += term1 * delta_n * Convert.ToDecimal(n - 2)
                    - Convert.ToDecimal(3) * delta_n * this.m2;
                this.m2 += this.m2 + term1;
            }
        }
    }

    public void Merge(Kurtosis Group)
    {
        // Put your code here

        this.n += Group.N;
        this.mean += Group.Mean;
        this.m2 += Group.M2;
        this.m3 += Group.M3;
        this.m4 += Group.M4;
    }

    public SqlDouble Terminate()
    {
        decimal kurtosis = (Convert.ToDecimal(n) * this.m4)
            / (this.m2 * this.m3) - 3;

        return new SqlDouble(Convert.ToDouble(kurtosis));
    }


    /*
     * The binary layout is as follows:
     * The first 16 bytes are the sumOfFirst decimal
     * The second 16 bytes are the sumOfSecond decimal
     * The third 16 bytes are the product decimal
     * Then, each 8 bytes alternates between the first and second doubles in the lists
     */
    public void Read(BinaryReader binaryReader)
    {
        this.n = binaryReader.ReadInt16();
        this.mean = binaryReader.ReadDecimal();
        this.m2 = binaryReader.ReadDecimal();
        this.m3 = binaryReader.ReadDecimal();
        this.m4 = binaryReader.ReadDecimal();
    }

    public void Write(BinaryWriter binaryWriter)
    {
        binaryWriter.Write(n);
        binaryWriter.Write(mean);
        binaryWriter.Write(m2);
        binaryWriter.Write(m3);
        binaryWriter.Write(m4);
    }

    // This is a place-holder member field
    private int n;
    private decimal mean;
    private decimal m2;
    private decimal m3;
    private decimal m4;

    public Int32 N
    {
        get { return this.n; }
    }

    public Decimal Mean
    {
        get { return this.mean; }
    }

    public Decimal M2
    {
        get { return this.M2; }
    }

    public Decimal M3
    {
        get { return this.M3; }
    }

    public Decimal M4
    {
        get { return this.M4; }
    }

}
