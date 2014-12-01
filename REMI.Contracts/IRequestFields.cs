using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace REMI.Contracts
{
    public interface IRequestFields : ILoggedItem,  REMI.Validation.IValidatable
    {
        Int32 FieldSetupID { get; set; }
        Int32 FieldTypeID  { get; set; }
        Int32 FieldValidationID  { get; set; }
        Int32 DisplayOrder  { get; set; }
        Int32 ColumnOrder { get; set; }
        Int32 OptionsTypeID { get; set; }
        Int32 RequestTypeID { get; set; }
        Int32 RequestID { get; set; }
        Int32 InternalField  { get; set; }
        String RequestType  { get; set; } 
        String Name  { get; set; }
        String FieldType { get; set; }
        String FieldValidation { get; set; }
        String IntField { get; set; }
        String ExtField  { get; set; }
        String RequestNumber { get; set; }
        String Category { get; set; }
        String Value { get; set; }
        String Description { get; set; }
        bool IsRequired  { get; set; }
        bool IsArchived { get; set; }
        bool IsFromExternalSystem  { get; set; }
        List<String> OptionsType  { get; set; }
        bool NewRequest { get; set; }
        Int32 ParentFieldSetupID { get; set; }
    }
}
