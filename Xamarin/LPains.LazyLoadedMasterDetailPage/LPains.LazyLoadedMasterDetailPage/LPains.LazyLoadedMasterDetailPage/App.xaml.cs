using FreshMvvm;
using LPains.LazyLoadedMasterDetailPage.Helpers;
using LPains.LazyLoadedMasterDetailPage.ViewModels;
using System;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

[assembly: XamlCompilation (XamlCompilationOptions.Compile)]
namespace LPains.LazyLoadedMasterDetailPage
{
	public partial class App : Application
	{
		public App ()
		{
			InitializeComponent();

            FreshPageModelResolver.PageModelMapper = new FreshViewModelMapper();
        }

        protected override void OnStart ()
		{
            var masterDetailNav = new MasterDetailNavigationContainer();
            masterDetailNav.Init("Menu", "ic_toolbar_Bars");
            masterDetailNav.AddPage<BlankViewModel>("Dashboard", "Dashboard", '\uf200'.ToString(), null); // piechart icon
            masterDetailNav.AddPage<BlankViewModel>("Item 1", "Items", '\uf128'.ToString(), null); // question icon
            masterDetailNav.AddPage<BlankViewModel>("Item 2", "Items", '\uf128'.ToString(), null); // question icon
            masterDetailNav.AddPage<BlankViewModel>("About", "Settings", '\uf129'.ToString(), null); // info icon
            masterDetailNav.AddPage<BlankViewModel>("User Profile", "Settings", '\uf007'.ToString(), null); // user icon

            MainPage = masterDetailNav;
            // Handle when your app starts
        }

		protected override void OnSleep ()
		{
			// Handle when your app sleeps
		}

		protected override void OnResume ()
		{
			// Handle when your app resumes
		}
	}
}
