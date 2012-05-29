using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.IO;


[Serializable]
[Microsoft.SqlServer.Server.SqlUserDefinedAggregate(Format.UserDefined, IsInvariantToDuplicates = false, IsInvariantToNulls = false, IsNullIfEmpty = true, IsInvariantToOrder = true, MaxByteSize = -1)]
public struct Pearsons : Microsoft.SqlServer.Server.IBinarySerialize
{
    // Based on http://www.cs.tufts.edu/comp/135/pearson.html
    //http://en.wikipedia.org/wiki/Pearson_product-moment_correlation_coefficient
    public void Init()
    {
        // Put your code here
        this.sumOfSquaresOfFirst = 0;
        this.sumOfSquaresOfSecond = 0;
        this.sumOfFirst = 0;
        this.sumOfSecond = 0;
        this.coProduct = 0;
        this.numberOfRecords = 0;
    }

    public void Accumulate(SqlDouble FirstValue, SqlDouble SecondValue)
    {
        // Put your code here
        if (FirstValue.IsNull != true && SecondValue.IsNull != true)
        {
            this.sumOfSquaresOfFirst += Convert.ToDecimal(FirstValue.Value) * Convert.ToDecimal(FirstValue.Value);
            this.sumOfSquaresOfSecond += Convert.ToDecimal(SecondValue.Value) * Convert.ToDecimal(SecondValue.Value);
            this.sumOfFirst += Convert.ToDecimal(FirstValue.Value);
            this.sumOfSecond += Convert.ToDecimal(SecondValue.Value);
            this.coProduct += Convert.ToDecimal(FirstValue.Value) * Convert.ToDecimal(SecondValue.Value);
            this.numberOfRecords++;
        }
    }

    public void Merge(Pearsons Group)
    {
        this.sumOfFirst += Group.SumOfFirst;
        this.sumOfSecond += Group.SumOfSecond;
        this.sumOfSquaresOfFirst += Group.SumOfSquaresOfFirst;
        this.sumOfSquaresOfSecond += Group.sumOfSquaresOfSecond;
        this.coProduct += Group.CoProduct;
    }

    public SqlDouble Terminate()
    {
        if (this.NumberOfRecords == 0)
        {
            return new SqlDouble();
        }
        decimal meanOfFirst = this.SumOfFirst / this.NumberOfRecords;
        decimal meanOfSecond = this.SumOfSecond / this.NumberOfRecords;

        decimal population_sd_x = Convert.ToDecimal(Math.Sqrt(Convert.ToDouble(this.SumOfSquaresOfFirst / this.NumberOfRecords)))
               - (meanOfFirst * meanOfSecond);

        decimal population_sd_y = Convert.ToDecimal(Math.Sqrt(Convert.ToDouble(this.SumOfSquaresOfSecond / this.NumberOfRecords)))
               - (meanOfFirst * meanOfSecond);

        decimal covariance = (this.CoProduct / this.NumberOfRecords)
            - (meanOfFirst * meanOfSecond);

        if (population_sd_x == 0 | population_sd_y == 0)
        {
            return new SqlDouble();
        }

        decimal correlation = covariance / (population_sd_x * population_sd_y);

        return new SqlDouble(Convert.ToDouble(correlation));
    }


    /*
     * The binary layout is as follows:
     * The first 16 bytes are the sumOfSquaresOfFirst decimal
     * The second 16 bytes are the sumOfSquaresOfSecond decimal
     * The third 16 bytes are the sumOfFirst decimal
     * The fourth 16 bytes are the sumOfSecond decimal
     * The fifth 16 bytes are the coProduct decimal
     * The last 8 bytes are the numberOfRecords long
     */
    public void Read(BinaryReader binaryReader)
    {
        this.sumOfSquaresOfFirst = binaryReader.ReadDecimal();
        this.sumOfSquaresOfSecond = binaryReader.ReadDecimal();
        this.sumOfFirst = binaryReader.ReadDecimal();
        this.sumOfSecond = binaryReader.ReadDecimal();
        this.coProduct = binaryReader.ReadDecimal();
        this.numberOfRecords = binaryReader.ReadInt64();
    }

    public void Write(BinaryWriter binaryWriter)
    {
        binaryWriter.Write(this.SumOfSquaresOfFirst);
        binaryWriter.Write(this.SumOfSquaresOfSecond);
        binaryWriter.Write(this.SumOfFirst);
        binaryWriter.Write(this.SumOfSecond);
        binaryWriter.Write(this.CoProduct);
        binaryWriter.Write(this.NumberOfRecords);
    }

    // This is a place-holder member field
    private decimal sumOfSquaresOfFirst;
    private decimal sumOfSquaresOfSecond;
    private decimal sumOfFirst;
    private decimal sumOfSecond;
    private decimal coProduct;
    private long numberOfRecords;

    public Decimal SumOfSquaresOfFirst
    {
        get { return this.sumOfSquaresOfFirst; }
    }

    public Decimal SumOfSquaresOfSecond
    {
        get { return this.sumOfSquaresOfSecond; }
    }

    public Decimal SumOfFirst
    {
        get { return this.sumOfFirst; }
    }

    public Decimal SumOfSecond
    {
        get { return this.sumOfSecond; }
    }

    public Decimal CoProduct
    {
        get { return this.coProduct; }
    }

    public Int64 NumberOfRecords
    {
        get { return this.numberOfRecords; }
    }

}
