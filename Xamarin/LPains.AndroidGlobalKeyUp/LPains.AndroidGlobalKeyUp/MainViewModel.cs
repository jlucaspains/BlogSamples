using Xamarin.Forms;

namespace LPains.AndroidGlobalKeyUp
{
    public class MainViewModel
    {
        public void OnAppearing()
        {
            // For this example, using the OnAppearing for subscription and OnDisappearing for 
            // unsubscription is overkill. However, when you start using ViewModels and
            // navigation, be careful to only subscribe to key up when your view is active
            // and make sure to unsubscribe when not.
            MessagingCenter.Subscribe<Application, string>(this, "GlobalKeyUp", (sender, evt) =>
            {
                // Don't display alerts like this. I was lazy and didn't want to connect 
                // the view and view model properly
                Application.Current.MainPage.DisplayAlert("Key up event", evt, "Ok");
            });
        }

        public void OnDisappearing()
        {
            // If you don't unsubscribe OnDisappearing, this view (or view model) will continue
            // to get events even when not visible anymore. That most likely is not desirable.
            MessagingCenter.Unsubscribe<Application, string>(this, "GlobalKeyUp");
        }
    }
}
