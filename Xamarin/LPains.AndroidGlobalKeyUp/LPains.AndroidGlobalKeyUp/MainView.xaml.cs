using System.ComponentModel;
using Xamarin.Forms;

namespace LPains.AndroidGlobalKeyUp
{
    // Learn more about making custom code visible in the Xamarin.Forms previewer
    // by visiting https://aka.ms/xamarinforms-previewer
    [DesignTimeVisible(false)]
    public partial class MainView : ContentPage
    {
        public MainView()
        {
            InitializeComponent();
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();

            var vm = BindingContext as MainViewModel;

            vm?.OnAppearing();
        }

        protected override void OnDisappearing()
        {
            base.OnDisappearing();

            var vm = BindingContext as MainViewModel;

            vm?.OnDisappearing();
        }
    }
}
