namespace Example.Models
{
    /// <summary>
    /// Represents a user in the system.
    /// </summary>
    public class User
    {
        public string Name { get; set; }
        public int Age { get; set; }

        /// <summary>
        /// Gets the display name.
        /// </summary>
        public string GetDisplayName()
        {
            return Name;
        }
    }

    /// <summary>
    /// Validates user data.
    /// </summary>
    public interface IValidator
    {
        bool Validate(string input);
    }

    internal class InternalHelper
    {
        private void DoSomething() { }
    }
}
