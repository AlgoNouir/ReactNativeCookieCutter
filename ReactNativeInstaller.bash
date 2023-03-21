# --------------------------------+
#           preinstalling         |
# --------------------------------+

# loger function clear all outputs and echo steps
logs=()
function echoLog {
    clear
    logs+=("$1")
    for logStr in "${!logs[@]}"; do
        echo "${logs[logStr]} ($((logStr + 1))/5)"
    done
    return
}

# get app name and set it to defualt
read -r -p "app name:(app) " appName
if [[ -z "${appName}" ]]; then
    appName="app"
fi

# --------------------------------+
#         install expo app        |
# --------------------------------+

# install blank typescript expo app
npx create-expo-app "$appName" --template expo-template-blank-typescript
cd "$appName" || exit

echoLog "✅ $appName install done"
# --------------------------------+
#         create home page        |
# --------------------------------+

# create page folder
mkdir pages

# create home file
cat > "./pages/home.tsx" <<- EOM
import * as React from "react";
import { View, Text } from "react-native";

export interface HomeProps {}

export default function Home(props: HomeProps) {
    return (
        <View className="w-screen h-screen items-center justify-center">
            <Text>your app is ready !!!</Text>
        </View>
    );
}
EOM


mkdir components

# --------------------------------+
#   install and config tailwind   |
# --------------------------------+

echo "installing nativewind ..."

# install tailwind
npm install nativewind
npm install --dev tailwindcss
npx tailwindcss init


# config tailwind
cat > "./tailwind.config.js" <<- EOM
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './App.{js,jsx,ts,tsx}', 
    './pages/**/*.{js,jsx,ts,tsx}', 
    './components/**/*.{js,jsx,ts,tsx}'
  ],
  theme: {
    colors: {
        primary: "#EDEDED",
        secondary: "#3C414A",
        background: "#EDEDED",
        card: "#FFF",
        text: "#3C414A",
        border: "#3C414A99",
        notification: "#AEBC4A",
    
        white: "#FFF",
        black: "#000",
        red: "#C4716C",
        green: "#AEBC4A",
        blue: "#3A5290",
    },
  },
  plugins: [],
}
EOM
sed -i '' "s#return {#return {plugins: ['nativewind/babel'],#" "babel.config.js"

# create core folder for export tailwind
mkdir core
cat > "./core/index.ts" <<- EOM
export const colors = require("../tailwind.config").theme.colors
EOM

# set className to components
echo "/// <reference types='nativewind/types' />" > app.d.ts

echoLog "✅ nativewind install done"

# --------------------------------+
#    install navigation and set   |
# --------------------------------+

echo "installing redux ..."

# install dependencies
npm install @reduxjs/toolkit react-redux

# create file
mkdir store
cat > "./store/store.ts" <<- EOM
import {
  Action,
  configureStore,
  ThunkAction,
} from '@reduxjs/toolkit';

export const store = configureStore({
  reducer: {
// This is where we add reducers.
// Since we don't have any yet, leave this empty
  },
});

export type AppDispatch = typeof store.dispatch;
export type RootState = ReturnType<typeof store.getState>;
export type AppThunk<ReturnType = void> = ThunkAction<
   ReturnType,
   RootState,
   unknown,
   Action<string>
 >;
EOM

cat > "./store/HOCs.ts" <<- EOM
import {
  TypedUseSelectorHook,
  useDispatch,
  useSelector,
} from 'react-redux';
import type {
  AppDispatch,
  RootState,
} from './store';

export const useAppDispatch = () => useDispatch<AppDispatch>();
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
EOM

echoLog "✅ redux install done"

# --------------------------------+
#    install navigation and set   |
# --------------------------------+

echo "installing the navigations ..."
npm install @react-navigation/native @react-navigation/native-stack
npx expo install react-native-screens react-native-safe-area-context

# set app navigations to home page
cat > "./App.tsx" <<- EOM
// base
import {NavigationContainer, DefaultTheme} from '@react-navigation/native';
import {createNativeStackNavigator} from '@react-navigation/native-stack';
import {colors} from "./core"
import { store } from "./store/store";
import { Provider } from 'react-redux';

// pages
import HomePage from "./pages/home"

const {Navigator, Screen} = createNativeStackNavigator();

export default function App() {
  return (
    <Provider store={store}>
      <NavigationContainer theme={{ ...DefaultTheme, colors }}>
        <Navigator>
          <Screen
            name="home"
            component={HomePage} />
        </Navigator>
      </NavigationContainer>
    </Provider>
  );
}
EOM

echoLog "✅ navigation install done"

# --------------------------------+
#        git init and commit      |
# --------------------------------+
echo "initial git and commit ..."

git init
git add -A
git commit -m "install the project via cookie"

echoLog "✅ git commited"

echo "happy hacking!!! 👑"